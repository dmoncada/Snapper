import SwiftUI

struct ThemeSection<Content: View>: View {
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    ForEach(sections: content) { section in
      VStack(alignment: .leading, spacing: 0) {
        if section.header.isEmpty == false {
          section.header
            .withThemeSectionHeader()
            .padding(.bottom, Padding.xl)
        }

        Group(subviews: section.content) { rows in
          VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
              rows[index]
                .padding(.vertical, Spacing.sm)

              if index < rows.count - 1 {
                Divider()
              }
            }
          }
        }

        if section.footer.isEmpty == false {
          section.footer
            .withThemeSectionFooter()
            .padding(.top, Padding.xl)
        }
      }
    }
  }
}

#if DEBUG
extension CaseIterable where Self: Equatable {
  var next: Self {
    let cases = Array(Self.allCases)

    if let index = cases.firstIndex(of: self) {
      return cases[(index + 1) % cases.count]
    }

    return cases[0]
  }
}

private enum LocationStatus: CaseIterable {
  case noLocation
  case locating
  case located
}

private struct ButtonRow: View {
  let leading: String
  let trailing: String

  @State private var isActive = false

  var body: some View {
    Button {
      isActive.toggle()
    } label: {
      LabeledContent {
        Text(trailing)
      } label: {
        HStack {
          PlaybackIndicator(isPlaying: isActive, progress: 0.25)
            .frame(width: 24)

          Text(leading)
        }
      }
      .labeledContentStyle(.withThemeFont(isActive: isActive))
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  @Previewable @State var status: LocationStatus = .noLocation

  VStack(spacing: 32) {
    ThemeSection {
      Section {
        LabeledContent("Left", value: "Right")
        LabeledContent("Left", value: "Right")
        LabeledContent("Left", value: "Right")

        switch status {
        case .noLocation:
          LabeledContent("Location", value: "No Location")

        case .locating:
          LabeledContent {
            ProgressView()
              .controlSize(.small)
          } label: {
            Text("Location")
          }

        case .located:
          DisclosureGroup {
            Rectangle()
              .fill(.red)
              .frame(height: 200)
              .frame(maxWidth: .infinity)
          } label: {
            Text("Location")
              .font(.sligoilMicroBold(.subheadline))
          }
          .disclosureGroupStyle(.plain)
        }
      } header: {
        Text("Album Information")
      }
    }
    .labeledContentStyle(.withThemeFont)

    ThemeSection {
      Section {
        ButtonRow(leading: "Left", trailing: "Right")
        ButtonRow(leading: "Left", trailing: "Right")
        ButtonRow(leading: "Left", trailing: "Right")
          .disabled(true)
      } header: {
        Text("Tracks")
      } footer: {
        Text("Tracks provided courtesy of iTunes.")
      }
    }

    Button("Next Status") {
      status = status.next
    }
    .buttonStyle(.borderedProminent)
  }
  .padding(.horizontal)
  .fullBackground(.themePrimary)
}
#endif
