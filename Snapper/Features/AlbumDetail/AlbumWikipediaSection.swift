import SwiftUI
import WebKit

struct AlbumWikipediaSection: View {
  let url: URL?
  let title: String
  let extract: String

  init(url: URL, title: String, extract: String) {
    self.url = url
    self.title = title
    self.extract = extract
  }

  init(_ info: WikipediaInfo) {
    self.url = info.url
    self.title = info.title ?? ""
    self.extract = info.extract ?? ""
  }

  @State private var articleExpanded = true

  private var attributedExtract: AttributedString {
    guard let attributed = try? AttributedString(markdown: extract) else {
      return AttributedString(extract)
    }

    return attributed
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
      DisclosureGroup(isExpanded: $articleExpanded) {
        Text(attributedExtract)
          .font(.gillSans(.body))
          .lineLimit(4)
          .padding(12)
      } label: {
        VStack(alignment: .leading, spacing: 0) {
          Text(title)
            .font(.zillaSlab(.headline).bold())

          Text(.detailSectionsWikiCaption)
            .font(.gillSans(.caption))
        }
      }
      .disclosureGroupStyle(.theme(.surface1))

      if let url {
        Link(destination: url) {
          Label(.detailSectionsWikiLink, systemImage: "arrow.up.right")
            .font(.zillaSlab(.caption))
            .foregroundStyle(.themeSecondary)
            .labelStyle(.trailingIcon)
            .imageScale(.small)
        }
        .stopPlayerOnUrl()
      }
    }
  }
}

#if DEBUG
#Preview {
  let url: URL = .applicationDirectory
  let title = "Lorem ipsum"
  let extract =
    "**Lorem ipsum** dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

  WithColorSchemes {
    AlbumWikipediaSection(url: url, title: title, extract: extract)
      .padding()
  }
}
#endif
