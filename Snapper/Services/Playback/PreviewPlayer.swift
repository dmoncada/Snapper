import AVFoundation
import MediaPlayer
import Observation

@MainActor
@Observable
final class PreviewPlayer {
  struct Preview: Equatable {
    let url: URL
    let title: String
  }

  init() {
    AVPlayer.isObservationEnabled = true

    configureRemoteCommands()
  }

  private(set) var isPlaying = false
  private(set) var preview: Preview?
  private(set) var duration: TimeInterval = 0
  private(set) var currentTime: TimeInterval = 0

  var progress: Double {
    guard duration > 0 else { return 0 }
    return min(max(currentTime / duration, 0), 1)
  }

  private static let fadeDuration: TimeInterval = 1

  @ObservationIgnored private var player: AVPlayer?
  @ObservationIgnored private var playbackId = UUID()
  @ObservationIgnored private var playbackTask: Task<Void, Never>?
  @ObservationIgnored private var timeObserver: Any?

  func play(_ url: URL, title: String? = nil) async {
    let id = UUID()
    playbackId = id

    do {
      try await Self.activateSession()
    } catch {
      guard playbackId == id else { return }
      await stopImmediately()
      return
    }

    guard playbackId == id else { return }

    playbackTask?.cancel()

    let item = AVPlayerItem(url: url)
    if let player {
      player.replaceCurrentItem(with: item)
    } else {
      player = AVPlayer(playerItem: item)
    }

    preview = Preview(
      url: url,
      title: title ?? url.deletingPathExtension().lastPathComponent,
    )

    observePlayback(of: item, id: id)

    player?.volume = 0
    player?.play()
    isPlaying = true

    updateNowPlayingInfo()
  }

  func pause() async {
    guard preview != nil, isPlaying else { return }

    player?.pause()
    isPlaying = false
    updateNowPlayingInfo()
  }

  func toggle() async {
    isPlaying
      ? await pause()
      : await resume()
  }

  private func resume() async {
    guard preview != nil, isPlaying == false else { return }

    player?.play()
    isPlaying = true
    updateNowPlayingInfo()
  }

  func stopImmediately() async {
    playbackId = UUID()
    playbackTask?.cancel()
    playbackTask = nil

    if let timeObserver, let player {
      player.removeTimeObserver(timeObserver)
      self.timeObserver = nil
    }

    player?.pause()
    player?.replaceCurrentItem(with: nil)
    player = nil

    isPlaying = false
    preview = nil
    duration = 0
    currentTime = 0

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

    await Self.deactivateSession()
  }

  private func configureRemoteCommands() {
    let center = MPRemoteCommandCenter.shared()

    center.playCommand.addTarget { [weak self] _ in
      Task { @MainActor [weak self] in
        await self?.resume()
      }
      return .success
    }

    center.pauseCommand.addTarget { [weak self] _ in
      Task { @MainActor [weak self] in
        await self?.pause()
      }
      return .success
    }

    center.togglePlayPauseCommand.addTarget { [weak self] _ in
      Task { @MainActor [weak self] in
        await self?.toggle()
      }
      return .success
    }

    center.nextTrackCommand.isEnabled = false
    center.previousTrackCommand.isEnabled = false
    center.changePlaybackPositionCommand.isEnabled = false
  }

  private func observePlayback(of item: AVPlayerItem, id: UUID) {
    playbackTask?.cancel()
    playbackTask = Task { @MainActor [weak self] in
      for await _ in NotificationCenter.default.notifications(
        named: AVPlayerItem.didPlayToEndTimeNotification,
        object: item,
      ) {
        guard let self, self.playbackId == id else { return }
        await self.stopImmediately()
        return
      }
    }

    guard let player else { return }

    if let timeObserver {
      player.removeTimeObserver(timeObserver)
    }

    timeObserver = player.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
      queue: .main,
    ) { [weak self, weak item] time in
      guard let item else { return }

      let current = time.seconds
      let duration = item.duration.seconds

      guard
        current.isFinite,
        duration.isFinite,
        duration > 0
      else { return }

      Task { @MainActor [weak self] in
        guard let self, self.playbackId == id else { return }

        self.player?.volume = Self.fadeVolume(at: current, duration: duration)
        self.currentTime = current
        self.duration = duration
      }
    }
  }

  private static func fadeVolume(at time: TimeInterval, duration: TimeInterval) -> Float {
    let fadeIn = time / fadeDuration
    let fadeOut = (duration - time) / fadeDuration
    return Float(min(max(min(fadeIn, fadeOut), 0), 1))
  }

  private func updateNowPlayingInfo() {
    guard let preview else { return }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
      MPNowPlayingInfoPropertyIsLiveStream: false,
      MPMediaItemPropertyTitle: preview.title,
    ]
  }

  private static func activateSession() async throws {
    #if os(iOS)
    let session = AVAudioSession.sharedInstance()

    if session.category != .playback {
      try session.setCategory(.playback)
    }

    #if compiler(>=6.4)
    if #available(iOS 27.0, *) {
      try await session.activate()
    } else {
      try session.setActive(true)
    }
    #else
    try session.setActive(true)
    #endif
    #endif
  }

  private static func deactivateSession() async {
    #if os(iOS)
    let session = AVAudioSession.sharedInstance()

    #if compiler(>=6.4)
    if #available(iOS 27.0, *) {
      _ = try? await session.deactivate()
    } else {
      try? session.setActive(false)
    }
    #else
    try? session.setActive(false)
    #endif
    #endif
  }
}

#if DEBUG
import SwiftUI

#Preview {
  @Previewable @State var player = PreviewPlayer()

  let titles = [
    "Take a Bow",
    "Starlight",
    "Supermassive Black Hole",
  ]

  let urls = [
    "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/b1/37/d2/b137d288-04c0-bdaf-9c93-e895a3931394/mzaf_8273800498014466621.plus.aac.p.m4a",
    "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/00/2c/2a/002c2a41-d59f-92a6-740a-35641b4e1e48/mzaf_9814325723002930170.plus.aac.p.m4a",
    "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/76/4a/63/764a63c0-9533-97ce-51a5-31a23b57f2eb/mzaf_3187296926844362175.plus.aac.p.m4a",
  ]
  .compactMap(URL.init(string:))

  if titles.count == urls.count {
    VStack {
      ForEach(Array(zip(titles, urls)).enumerated(), id: \.offset) { _, pair in
        let (title, url) = pair
        let isPlaying = title == player.preview?.title

        LabeledContent(title) {
          PlaybackButton(isPlaying: isPlaying, progress: player.progress) {
            Task {
              isPlaying
                ? await player.stopImmediately()
                : await player.play(url, title: title)
            }
          }
          .frame(width: 24)
        }
        .foregroundStyle(
          isPlaying
            ? .themeRed
            : .themeSeafoam
        )
      }
    }
    .padding()
  } else {
    ProgressView()
  }
}
#endif
