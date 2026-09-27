//
//  ToolbarTitle.swift
//  Snapper
//
//  Created by David Moncada on 9/26/26.
//

import SwiftUI

struct ToolbarTitle: ToolbarContent {
  let title: String

  init(_ title: String) {
    self.title = title
  }

  var body: some ToolbarContent {
    ToolbarItem(placement: .automatic) {
      Text(title)
        .frame(
          maxWidth: .infinity,
          alignment: .leading
        )
        .font(.basteleurBold(.title))
        .foregroundStyle(.themePrimaryInverted)
    }
    .sharedBackgroundVisibility(.hidden)
  }
}
