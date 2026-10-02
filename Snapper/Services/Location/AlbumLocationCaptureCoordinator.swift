import CoreLocation
import OSLog
import Observation
import SwiftData

@MainActor
@Observable
final class AlbumLocationCaptureCoordinator {
  private let locator = LocationService()
  private var isProcessing = false
  private var needsRetry = false

  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Snapper",
    category: "AlbumLocationCapture",
  )

  func resumePending(in context: ModelContext) {
    if isProcessing {
      logger.info("Scan requested while capture is running; another pass is queued")
      needsRetry = true
      return
    }

    logger.info("Starting scan for albums awaiting location")
    isProcessing = true

    // The pending state lives in SwiftData, so a fresh coordinator can resume after relaunch.
    Task {
      await processPending(in: context)
      isProcessing = false
      logger.info("Location scan finished")

      if needsRetry {
        logger.info("Running queued scan")
        needsRetry = false
        resumePending(in: context)
      }
    }
  }

  private func processPending(in context: ModelContext) async {
    var processedIDs = Set<UUID>()
    do {
      let entries = try context.fetch(FetchDescriptor<AlbumEntry>())
      let pendingCount =
        entries.filter {
          $0.locationCaptureStatusRaw == AlbumLocationStatus.pending.rawValue
        }
        .count
      logger.info("Scan found \(entries.count) albums; \(pendingCount) pending")

      while let entry = try context.fetch(FetchDescriptor<AlbumEntry>())
        .filter({
          $0.locationCaptureStatusRaw == AlbumLocationStatus.pending.rawValue
            && processedIDs.contains($0.id) == false
        })
        .min(by: { $0.selectedAt < $1.selectedAt })
      {
        logger.info("Processing album \(entry.id.uuidString, privacy: .public)")
        processedIDs.insert(entry.id)
        await captureLocation(for: entry.id, in: context)
      }
    } catch {
      logger.error(
        "Unable to fetch pending albums: \(error.localizedDescription, privacy: .public)"
      )
      // Keep pending entries in the store for the next activation.
    }
  }

  private func captureLocation(for id: UUID, in context: ModelContext) async {
    guard
      let entry = findEntry(by: id, in: context),
      entry.locationCaptureStatusRaw == AlbumLocationStatus.pending.rawValue
    else {
      logger.info("Skipping album \(id.uuidString, privacy: .public): missing or no longer pending")
      return
    }

    let selectedAt = entry.selectedAt
    let age = Date.now.timeIntervalSince(selectedAt)

    logger.info("Album \(id.uuidString, privacy: .public) was added \(age) seconds ago")

    let outcome: AlbumLocationStatus
    var coordinate: CLLocationCoordinate2D?
    var horizontalAccuracy: Double?

    if age < 120 {
      do {
        logger.info("Requesting one location for album \(id.uuidString, privacy: .public)")
        let location = try await locator.getLocation()
        let fixOffset = location.timestamp.timeIntervalSince(selectedAt)
        logger.info(
          "Received fix for album \(id.uuidString, privacy: .public): accuracy \(location.horizontalAccuracy) m; time offset \(fixOffset) s"
        )

        if location.horizontalAccuracy >= 0,
          location.horizontalAccuracy.isFinite,
          CLLocationCoordinate2DIsValid(location.coordinate),
          abs(fixOffset) <= 120
        {
          coordinate = location.coordinate
          horizontalAccuracy = location.horizontalAccuracy
          outcome = .captured
          logger.info("Accepted fix for album \(id.uuidString, privacy: .public)")
        } else {
          outcome = .unavailable
          logger.info(
            "Rejected fix for album \(id.uuidString, privacy: .public): stale or invalid"
          )
        }
      } catch LocationError.permissionDenied, LocationError.permissionRestricted {
        outcome = .denied
        logger.info(
          "Location permission denied or restricted for album \(id.uuidString, privacy: .public)"
        )
      } catch {
        outcome = .unavailable
        logger.error(
          "Location request failed for album \(id.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)"
        )
      }
    } else {
      outcome = .unavailable
      logger.info(
        "Skipping location request for album \(id.uuidString, privacy: .public): capture window expired"
      )
    }

    // The album may have been deleted while Core Location was resolving.
    guard
      let current = findEntry(by: id, in: context),
      current.locationCaptureStatusRaw == AlbumLocationStatus.pending.rawValue
    else {
      logger.info(
        "Dropping result for album \(id.uuidString, privacy: .public): deleted or status changed"
      )
      return
    }

    if let coordinate {
      current.latitude = coordinate.latitude
      current.longitude = coordinate.longitude
      current.locationHorizontalAccuracy = horizontalAccuracy
    }

    current.locationCaptureStatusRaw = outcome.rawValue

    do {
      try context.save()
      logger.info(
        "Saved location status \(outcome.rawValue, privacy: .public) for album \(id.uuidString, privacy: .public)"
      )
    } catch {
      logger.error(
        "Could not save location status for album \(id.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)"
      )
      // Keep this album eligible for another attempt without rolling back unrelated edits.
      current.latitude = nil
      current.longitude = nil
      current.locationHorizontalAccuracy = nil
      current.locationCaptureStatusRaw = AlbumLocationStatus.pending.rawValue
    }
  }

  private func findEntry(by id: UUID, in context: ModelContext) -> AlbumEntry? {
    do {
      return try context.fetch(FetchDescriptor<AlbumEntry>())
        .first { $0.id == id }
    } catch {
      logger.error(
        "Could not fetch album \(id.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)"
      )
      return nil
    }
  }
}
