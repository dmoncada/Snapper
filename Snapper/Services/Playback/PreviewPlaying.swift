import Foundation
import SwiftUI

@MainActor
protocol PreviewPlaying {
  var isPlaying: Bool { get }
  var preview: PreviewPlayer.Preview? { get }
  var duration: TimeInterval { get }
  var currentTime: TimeInterval { get }
  var progress: Double { get }

  func play(_ url: URL, title: String?) async
  func pause() async
  func toggle() async
  func stopImmediately() async
}

@MainActor
@Observable
final class NullPreviewPlayer: PreviewPlaying {
  private(set) var isPlaying = false
  private(set) var preview: PreviewPlayer.Preview? = nil
  private(set) var duration: TimeInterval = 0
  private(set) var currentTime: TimeInterval = 0

  var progress: Double { 0 }

  func play(_ url: URL, title: String? = nil) async {}
  func pause() async {}
  func toggle() async {}
  func stopImmediately() async {}
}

extension PreviewPlaying where Self == NullPreviewPlayer {
  static var null: Self { Self() }
}
