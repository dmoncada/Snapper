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
  @ObservationIgnored private var playbackRequestID = UUID()

  func toggle(_ track: AlbumTrack, artist: String, album: String) async {
    guard let url = track.previewUrl else { return }

    if currentTrack?.id == track.id {
      if isPlaying == false {
        await resume()
      }
      return
    }

    let requestID = UUID()
    playbackRequestID = requestID

    do {
      try await activateAudioSession()

    } catch {
      guard playbackRequestID == requestID else { return }
      failedTrackId = track.id
      await stop()
      return
    }

    guard playbackRequestID == requestID else { return }

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

  func resume() async {
    guard let trackID = currentTrack?.id else { return }

    let requestID = UUID()
    playbackRequestID = requestID

    do {
      try await activateAudioSession()
    } catch {
      guard playbackRequestID == requestID else { return }
      failedTrackId = trackID
      await stop()
      return
    }

    guard playbackRequestID == requestID, currentTrack?.id == trackID else { return }
    player?.play()
    isPlaying = true
    updateNowPlaying()
  }

  func stop() async {
    playbackRequestID = UUID()
    player?.pause()
    player?.replaceCurrentItem(with: nil)
    player = nil
    currentTrack = nil
    artist = ""
    album = ""
    isPlaying = false
    itemIdentifier = nil
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

    _ = try? await AVAudioSession.sharedInstance().deactivate(
      options: .notifyOthersOnDeactivation)
  }

  func handleItemStatus(_ status: AVPlayerItem.Status?) async {
    if status == .failed {
      failedTrackId = currentTrack?.id
      await stop()
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
        await stop()
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
        failedTrackId = currentTrack?.id
        await stop()
        return
      }
    }
  }

  private func activateAudioSession() async throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .default)
    _ = try await session.activate()
  }

  private func installRemoteCommandsIfNeeded() {
    if remoteCommandsInstalled { return }
    defer { remoteCommandsInstalled = true }

    let commands = MPRemoteCommandCenter.shared()

    commands.playCommand.addTarget { [weak self] _ in
      Task { @MainActor in await self?.resume() }
      return .success
    }
    commands.pauseCommand.addTarget { [weak self] _ in
      Task { @MainActor in self?.pause() }
      return .success
    }
    commands.togglePlayPauseCommand.addTarget { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }
        if self.isPlaying {
          self.pause()
        } else {
          await self.resume()
        }
      }
      return .success
    }
    commands.nextTrackCommand.isEnabled = false
    commands.previousTrackCommand.isEnabled = false
  }
}
