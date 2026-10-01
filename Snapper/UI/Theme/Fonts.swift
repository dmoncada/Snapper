import SwiftUI

enum CustomFont: String, CaseIterable, Identifiable {
  case basteleurBold = "Basteleur-Bold"
  case basteleurMoonlight = "Basteleur-Moonlight"

  case libreCaslonTextRegular = "LibreCaslonText-Regular"
  case libreCaslonTextItalic = "LibreCaslonText-Italic"
  case libreCaslonTextBold = "LibreCaslonText-Bold"

  case sligoilMicro = "Sligoil-Micro"
  case sligoilMicroMedium = "Sligoil-MicroMedium"
  case sligoilMicroBold = "Sligoil-MicroBold"

  case vg5000 = "VG5000-Regular"

  var id: String { rawValue }
}

#if canImport(AppKit)
typealias PlatformFont = NSFont
#elseif canImport(UIKit)
typealias PlatformFont = UIFont
#endif

extension PlatformFont.TextStyle {
  init(_ textStyle: Font.TextStyle) {
    switch textStyle {
    case .largeTitle:
      #if os(tvOS)
      self = .title1
      #else
      self = .largeTitle
      #endif
    case .title:
      self = .title1
    case .title2:
      self = .title2
    case .title3:
      self = .title3
    case .headline:
      self = .headline
    case .subheadline:
      self = .subheadline
    case .body:
      self = .body
    case .callout:
      self = .callout
    case .footnote:
      self = .footnote
    case .caption:
      self = .caption1
    case .caption2:
      self = .caption2
    #if os(visionOS)
    case .extraLargeTitle:
      self = .extraLargeTitle
    case .extraLargeTitle2:
      self = .extraLargeTitle2
    #endif
    @unknown default:
      self = .body
    }
  }
}

extension Font {
  static func custom(_ font: CustomFont, _ textStyle: Font.TextStyle) -> Font {
    .custom(font.id, size: baseSize(for: textStyle), relativeTo: textStyle)
  }

  static func baseSize(for textStyle: Font.TextStyle) -> CGFloat {
    #if canImport(AppKit)
    NSFontDescriptor
      .preferredFontDescriptor(forTextStyle: .init(textStyle))
      .pointSize

    #else
    UIFontDescriptor
      .preferredFontDescriptor(
        withTextStyle: .init(textStyle),
        compatibleWith: UITraitCollection(preferredContentSizeCategory: .large),
      )
      .pointSize
    #endif
  }
}

extension Font {
  static func basteleurBold(_ textStyle: Font.TextStyle) -> Font {
    .custom(.basteleurBold, textStyle)
  }

  static func basteleurMoonlight(_ textStyle: Font.TextStyle) -> Font {
    .custom(.basteleurMoonlight, textStyle)
  }

  static func libreCaslonTextRegular(_ textStyle: Font.TextStyle) -> Font {
    .custom(.libreCaslonTextRegular, textStyle)
  }

  static func libreCaslonTextItalic(_ textStyle: Font.TextStyle) -> Font {
    .custom(.libreCaslonTextItalic, textStyle)
  }

  static func libreCaslonTextBold(_ textStyle: Font.TextStyle) -> Font {
    .custom(.libreCaslonTextBold, textStyle)
  }

  static func sligoilMicro(_ textStyle: Font.TextStyle) -> Font {
    .custom(.sligoilMicro, textStyle)
  }

  static func sligoilMicroMedium(_ textStyle: Font.TextStyle) -> Font {
    .custom(.sligoilMicroMedium, textStyle)
  }

  static func sligoilMicroBold(_ textStyle: Font.TextStyle) -> Font {
    .custom(.sligoilMicroBold, textStyle)
  }

  static func vg5000(_ textStyle: Font.TextStyle) -> Font {
    .custom(.vg5000, textStyle)
  }
}

#if DEBUG
private func installedFontNames(matching queries: [String]) -> [String] {
  #if canImport(AppKit)
  let installed = NSFontManager.shared.availableFonts
  #elseif canImport(UIKit)
  let installed = PlatformFont.familyNames
    .flatMap(PlatformFont.fontNames(forFamilyName:))
  #endif

  return
    installed
    .filter { font in
      queries.isEmpty || queries.contains { font.localizedStandardContains($0) }
    }
    .sorted()
}

private struct InstalledFontsList: View {
  let fontNames = installedFontNames(matching: CustomFont.allCases.map(\.id))

  var body: some View {
    List(fontNames, id: \.self) { name in
      Text(name)
        .font(.custom(name, size: 32, relativeTo: .title))
        .minimumScaleFactor(0.5)
        .scaledToFit()
    }
  }
}

private struct FontSpecimenView: View {
  private let specimens = CustomFont.allCases

  var body: some View {
    List(specimens) { font in
      VStack(alignment: .leading) {
        Text("Hello, world!")
          .font(.custom(font, .title))
        Text(font.id)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview("Installed") {
  InstalledFontsList()
}

#Preview("Specimens") {
  FontSpecimenView()
}
#endif
