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
            .withThemeSectionHeaderStyle()
            .padding(.bottom, Padding.xl)
        }

        Group(subviews: section.content) { rows in
          VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
              rows[index]
                .padding(.vertical, Spacing.sm)

              if index < rows.count - 1 {
                Divider()
                  .withThemeDividerStyle()
              }
            }
          }
        }

        if section.footer.isEmpty == false {
          section.footer
            .withThemeSectionFooterStyle()
            .padding(.top, Padding.xl)
        }
      }
    }
    .labeledContentStyle(.withThemeFont)
    .foregroundStyle(
      .themePrimary,
      .themeSecondary,
    )
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
      HStack(spacing: Spacing.sm) {
        ProgressView(value: 0.25)
          .progressViewStyle(.playback(isPlaying: isActive))

        LabeledContent(leading, value: trailing)
      }
      .foregroundStyle(
        isActive ? .accent : .themePrimary,
        isActive ? .accent : .themeSecondary,
      )
      .contentShape(.rect)
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
          DisclosureGroup("Location") {
            Rectangle()
              .fill(.red)
              .frame(height: 200)
              .frame(maxWidth: .infinity)
          }
          .disclosureGroupStyle(.plain)
        }
      } header: {
        Text("Album Information")
      }
    }

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
  .withFullBackground()
}
#endif
