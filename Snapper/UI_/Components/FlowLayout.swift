import SwiftUI

struct FlowLayout: Layout {
  let alignment: HorizontalAlignment
  let spacing: CGFloat
  let lineSpacing: CGFloat

  init(
    alignment: HorizontalAlignment = .leading,
    spacing: CGFloat = Spacing.xs,
    lineSpacing: CGFloat = Spacing.xs,
  ) {
    self.alignment = alignment
    self.spacing = spacing
    self.lineSpacing = lineSpacing
  }

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout (),
  ) -> CGSize {
    let sizes = subviews.map {
      $0.sizeThatFits(.unspecified)
    }

    let priorities = subviews.map(\.priority)

    let result = arrange(
      sizes: sizes,
      priorities: priorities,
      maxWidth: proposal.width ?? .infinity,
    )

    return CGSize(
      width: proposal.width ?? result.width,
      height: result.height,
    )
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout (),
  ) {
    let sizes = subviews.map {
      $0.sizeThatFits(.unspecified)
    }

    let priorities = subviews.map(\.priority)

    let result = arrange(
      sizes: sizes,
      priorities: priorities,
      maxWidth: bounds.width,
    )

    for (index, position) in result.positions.enumerated() {
      subviews[index]
        .place(
          at: CGPoint(
            x: bounds.minX + position.x,
            y: bounds.minY + position.y,
          ),
          proposal: ProposedViewSize(sizes[index]),
        )
    }
  }

  private func arrange(
    sizes: [CGSize],
    priorities: [Double],
    maxWidth: CGFloat,
  ) -> (
    positions: [CGPoint],
    width: CGFloat,
    height: CGFloat
  ) {
    if sizes.isEmpty {
      return ([], 0, 0)
    }

    // Higher-priority subviews are placed first.
    // Preserve declaration order for equal priorities.
    let orderedIndices = sizes.indices.sorted {
      if priorities[$0] != priorities[$1] {
        return priorities[$0] > priorities[$1]
      }

      return $0 < $1
    }

    var rows: [[Int]] = []
    var currentRow: [Int] = []

    var x: CGFloat = 0
    var rowHeight: CGFloat = 0
    var totalHeight: CGFloat = 0
    var maxRowWidth: CGFloat = 0

    for index in orderedIndices {
      let size = sizes[index]

      if currentRow.isEmpty == false && x + size.width > maxWidth {
        rows.append(currentRow)

        maxRowWidth = max(
          maxRowWidth,
          x - spacing,
        )

        currentRow = []

        x = 0

        totalHeight += rowHeight + lineSpacing

        rowHeight = 0
      }

      currentRow.append(index)

      x += size.width + spacing
      rowHeight = max(rowHeight, size.height)
    }

    if currentRow.isEmpty == false {
      rows.append(currentRow)

      totalHeight += rowHeight

      maxRowWidth = max(
        maxRowWidth,
        x - spacing,
      )
    }

    let alignmentWidth =
      maxWidth.isFinite
      ? maxWidth
      : maxRowWidth

    var positions = Array(
      repeating: CGPoint.zero,
      count: sizes.count,
    )

    var rowY: CGFloat = 0

    for row in rows {
      let rowHeight =
        row
        .map { sizes[$0].height }
        .max() ?? 0

      var rowWidth: CGFloat = 0
      rowWidth += row.reduce(CGFloat.zero) { $0 + sizes[$1].width }
      rowWidth += CGFloat(max(0, row.count - 1)) * spacing

      let offset: CGFloat

      switch alignment {
      case .center:
        offset = max(0, (alignmentWidth - rowWidth) / 2)

      case .trailing:
        offset = max(0, alignmentWidth - rowWidth)

      default:
        offset = 0
      }

      var rowX = offset

      for index in row {
        positions[index] = CGPoint(
          x: rowX,
          y: rowY,
        )

        rowX += sizes[index].width + spacing
      }

      rowY += rowHeight + lineSpacing
    }

    return (
      positions,
      maxRowWidth,
      totalHeight,
    )
  }
}

#if DEBUG
#Preview("Alignment Comparison") {
  ScrollView {
    VStack(spacing: 24) {
      alignmentPreview(.leading)
      alignmentPreview(.center)
      alignmentPreview(.trailing)
    }
    .padding()
    .frame(maxWidth: .infinity)
  }
}

#Preview("Spacing Variations") {
  ScrollView {
    VStack(alignment: .leading, spacing: 24) {
      Text("Compact")
      tagLayout(spacing: 4, lineSpacing: 4)

      Text("Default")
      tagLayout(spacing: 8, lineSpacing: 8)

      Text("Relaxed")
      tagLayout(spacing: 16, lineSpacing: 20)
    }
    .padding()
  }
}

#Preview("Narrow Container") {
  ScrollView {
    VStack(spacing: 20) {
      FlowLayout(alignment: .leading) {
        sampleTags
      }
      .border(.red)

      FlowLayout(alignment: .center) {
        sampleTags
      }
      .border(.red)

      FlowLayout(alignment: .trailing) {
        sampleTags
      }
      .border(.red)
    }
    .frame(width: 180)
    .padding()
  }
  .frame(maxWidth: .infinity)
}

#Preview("Single and Empty") {
  ScrollView {
    VStack(spacing: 20) {
      FlowLayout(alignment: .trailing) {
        tag("Single")
      }
      .frame(maxWidth: .infinity)
      .border(.red)

      FlowLayout(alignment: .trailing) {
        EmptyView()
      }
      .frame(maxWidth: .infinity)
      .border(.red)
    }
    .padding()
  }
}

// MARK: - Helpers

private func alignmentPreview(
  _ alignment: HorizontalAlignment
) -> some View {
  VStack(alignment: .leading, spacing: 8) {
    Text(alignmentName(alignment))
      .font(.headline)

    FlowLayout(
      alignment: alignment,
      spacing: 8,
      lineSpacing: 8,
    ) {
      sampleTags
    }
    .frame(maxWidth: .infinity)
    .border(.red)
  }
}

private func tagLayout(
  spacing: CGFloat,
  lineSpacing: CGFloat,
) -> some View {
  FlowLayout(
    spacing: spacing,
    lineSpacing: lineSpacing,
  ) {
    sampleTags
  }
  .frame(maxWidth: .infinity)
  .border(.red)
}

private var sampleTags: some View {
  Group {
    tag("US")
    tag("2026")
    tag("Vinyl")
      .layoutPriority(1)
    tag("Limited Edition")
      .layoutPriority(2)
    tag("New")
    tag("Collector")
    tag("Record Store")
  }
}

private func tag(_ title: String) -> some View {
  Text(title)
    .font(.headline)
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(.gray.opacity(0.15))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .fixedSize()
}

private func alignmentName(
  _ alignment: HorizontalAlignment
) -> String {
  switch alignment {
  case .leading: "Leading"
  case .center: "Center"
  case .trailing: "Trailing"
  default: "Custom"
  }
}
#endif
