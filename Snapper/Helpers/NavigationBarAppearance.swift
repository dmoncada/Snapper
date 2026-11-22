import SwiftUI

extension Font {
  func uiFont(
    in context: Font.Context = EnvironmentValues().fontResolutionContext
  ) -> UIFont {
    resolve(in: context).ctFont as UIFont
  }
}

extension Color {
  func uiColor() -> UIColor {
    UIColor(self)
  }
}

enum NavigationBarAppearance {
  static func configure(in context: Font.Context) {
    let appearance = UINavigationBarAppearance()
    let color = Color.themePrimary.uiColor()

    appearance.largeTitleTextAttributes = [
      .font: Font.zillaSlab(.largeTitle).bold().uiFont(in: context),
      .foregroundColor: color,
    ]
    appearance.titleTextAttributes = [
      .font: Font.zillaSlab(.headline).bold().uiFont(in: context),
      .foregroundColor: color,
    ]

    appearance.largeSubtitleTextAttributes = [
      .font: Font.zillaSlab(.title).uiFont(),
      .foregroundColor: color,
    ]
    appearance.subtitleTextAttributes = [
      .font: Font.zillaSlab(.caption).uiFont(),
      .foregroundColor: color,
    ]

    let navigationBar = UINavigationBar.appearance()
    navigationBar.standardAppearance = appearance
  }
}
