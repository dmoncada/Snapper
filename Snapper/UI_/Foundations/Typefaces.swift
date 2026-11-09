import SwiftUI

enum CustomFont: String, CaseIterable, Identifiable {
  case basteleurBold = "Basteleur-Bold"
  case basteleurMoonlight = "Basteleur-Moonlight"

  case libreCaslonTextRegular = "LibreCaslonText-Regular"
  case libreCaslonTextItalic = "LibreCaslonText-Italic"
  case libreCaslonTextBold = "LibreCaslonText-Bold"

  case interRegular = "Inter-Regular"
  case interItalic = "Inter-Italic"

  case zillaSlabRegular = "ZillaSlab-Regular"
  case zillaSlabItalic = "ZillaSlab-Italic"
  case zillaSlabBold = "ZillaSlab-Bold"
  case zillaSlabBoldItalic = "ZillaSlab-BoldItalic"

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
  static func custom(_ fontName: String, _ textStyle: Font.TextStyle) -> Font {
    .custom(fontName, size: baseSize(for: textStyle), relativeTo: textStyle)
  }

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

  static func gillSans(_ textStyle: Font.TextStyle) -> Font {
    .custom("Gill Sans", textStyle)
  }

  static func inter(_ textStyle: Font.TextStyle) -> Font {
    .custom(.interRegular, textStyle)
  }

  static func zillaSlab(_ textStyle: Font.TextStyle) -> Font {
    .custom(.zillaSlabRegular, textStyle)
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
  private let fontNames = installedFontNames(matching: CustomFont.allCases.map(\.id))

  var body: some View {
    List(fontNames, id: \.self) { name in
      Text(name)
        .font(.custom(name, size: 32, relativeTo: .title))
        .minimumScaleFactor(0.3)
    }
  }
}

private struct FontSpecimenView: View {
  var body: some View {
    List(CustomFont.allCases) { font in
      VStack(alignment: .leading) {
        Text("MusicSnap")
          .font(.custom(font, .title))
        Text(font.id)
          .font(.caption)
          .foregroundStyle(.blue.mix(with: .black, by: 0.125))
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

#Preview("Zilla Slab Styles") {
  List {
    Text("Zilla Slab Regular")
      .font(.zillaSlab(.title))
    Text("Zilla Slab Italic")
      .font(.zillaSlab(.title).italic())
    Text("Zilla Slab Bold")
      .font(.zillaSlab(.title).bold())
    Text("Zilla Slab Bold Italic")
      .font(.zillaSlab(.title).bold().italic())
  }
}

#Preview("Gill Sans Typeface") {
  let font = "Gill Sans"
  List(Font.Weight.allCases, id: \.self) { weight in
    Text("\(font) \(weight.name)")
      .font(.custom(font, .title).weight(weight))
  }
}

#Preview("Inter Typeface") {
  List(Font.Weight.allCases, id: \.self) { weight in
    Text("Inter \(weight.name)")
      .font(.inter(.title).weight(weight))
  }
}
#endif
