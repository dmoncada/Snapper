import AVFoundation
import MediaPlayer
import Observation

@MainActor
@Observable
final class PreviewPlaybackController {
  private(set) var currentTrack: AlbumTrack?
  private(set) var artist = ""
  private(set) var album = ""
  private(set) var isPlaying = false
  private(set) var failedTrackId: String?
  private(set) var itemIdentifier: UUID?
  private(set) var player: AVPlayer?

  @ObservationIgnored private var remoteCommandsInstalled = false

  func toggle(_ track: AlbumTrack, artist: String, album: String) {
    guard let url = track.previewUrl else { return }

    if currentTrack?.id == track.id {
      isPlaying ? pause() : resume()
      return
    }

    do {
      try activateAudioSession()
    } catch {
      fail(trackId: track.id)
      return
    }

    installRemoteCommandsIfNeeded()
    failedTrackId = nil
    currentTrack = track
    self.artist = artist
    self.album = album
    isPlaying = true
    itemIdentifier = UUID()

    let item = AVPlayerItem(url: url)
    if let player {
      player.replaceCurrentItem(with: item)
      player.play()
    } else {
      let player = AVPlayer(playerItem: item)
      self.player = player
      player.play()
    }
    updateNowPlaying()
  }

  func pause() {
    guard currentTrack != nil else { return }
    player?.pause()
    isPlaying = false
    updateNowPlaying()
  }

  func resume() {
    guard currentTrack != nil else { return }
    do {
      try activateAudioSession()
    } catch {
      fail(trackId: currentTrack?.id)
      return
    }
    player?.play()
    isPlaying = true
    updateNowPlaying()
  }

  func stop() {
    player?.pause()
    player?.replaceCurrentItem(with: nil)
    player = nil
    currentTrack = nil
    artist = ""
    album = ""
    isPlaying = false
    itemIdentifier = nil
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    try? AVAudioSession.sharedInstance().setActive(
      false, options: .notifyOthersOnDeactivation)
  }

  func handleItemStatus(_ status: AVPlayerItem.Status?) {
    if status == .failed {
      fail(trackId: currentTrack?.id)
    } else if status == .readyToPlay {
      updateNowPlaying()
    }
  }

  func updateNowPlaying() {
    guard let currentTrack else { return }
    let elapsed = player?.currentTime().seconds ?? 0
    var info: [String: Any] = [
      MPMediaItemPropertyTitle: currentTrack.title,
      MPMediaItemPropertyArtist: artist,
      MPMediaItemPropertyAlbumTitle: album,
      MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed.isFinite ? elapsed : 0,
    ]
    if let duration = player?.currentItem?.duration.seconds, duration.isFinite {
      info[MPMediaItemPropertyPlaybackDuration] = duration
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }

  func observeItemEnd() async {
    guard let itemIdentifier else { return }
    for await notification in NotificationCenter.default.notifications(
      named: AVPlayerItem.didPlayToEndTimeNotification)
    {
      if Task.isCancelled { return }
      guard self.itemIdentifier == itemIdentifier else { return }
      if let endedItem = notification.object as? AVPlayerItem,
        endedItem === player?.currentItem
      {
        stop()
        return
      }
    }
  }

  func observeItemFailure() async {
    guard let itemIdentifier else { return }
    for await notification in NotificationCenter.default.notifications(
      named: AVPlayerItem.failedToPlayToEndTimeNotification)
    {
      if Task.isCancelled { return }
      guard self.itemIdentifier == itemIdentifier else { return }
      if let failedItem = notification.object as? AVPlayerItem,
        failedItem === player?.currentItem
      {
        fail(trackId: currentTrack?.id)
        return
      }
    }
  }

  private func fail(trackId: String?) {
    stop()
    failedTrackId = trackId
  }

  private func activateAudioSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .default)
    try session.setActive(true)
  }

  private func installRemoteCommandsIfNeeded() {
    if remoteCommandsInstalled { return }
    defer { remoteCommandsInstalled = true }

    let commands = MPRemoteCommandCenter.shared()

    commands.playCommand.addTarget { [weak self] _ in
      Task { @MainActor in self?.resume() }
      return .success
    }
    commands.pauseCommand.addTarget { [weak self] _ in
      Task { @MainActor in self?.pause() }
      return .success
    }
    commands.togglePlayPauseCommand.addTarget { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }
        self.isPlaying ? self.pause() : self.resume()
      }
      return .success
    }
    commands.nextTrackCommand.isEnabled = false
    commands.previousTrackCommand.isEnabled = false
  }
}
