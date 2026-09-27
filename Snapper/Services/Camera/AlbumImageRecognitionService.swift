import Foundation
import Vision

nonisolated struct AlbumImageRecognitionService: Sendable {
  func recognize(in imageData: Data) async throws -> AlbumImageRecognition {
    var barcodeRequest = DetectBarcodesRequest()
    barcodeRequest.symbologies = [.ean8, .ean13, .upce]

    var textRequest = RecognizeTextRequest()
    textRequest.recognitionLevel = .accurate

    let requestHandler = ImageRequestHandler(imageData)
    let barcodeObservations: [BarcodeObservation]

    do {
      barcodeObservations = try await requestHandler.perform(barcodeRequest)

    } catch {
      try Task.checkCancellation()
      barcodeObservations = []
    }

    let textObservations = try await requestHandler.perform(textRequest)

    let barcode =
      barcodeObservations
      .sorted { $0.confidence > $1.confidence }
      .compactMap { observation -> String? in
        guard let payload = observation.payloadString else { return nil }
        let digits = String(payload.filter { $0 >= "0" && $0 <= "9" })
        guard digits.count >= 8 else { return nil }
        return digits
      }
      .first

    var seenText = Set<String>()
    let textQuery =
      textObservations
      .compactMap { observation -> String? in
        guard
          let candidate = observation.topCandidates(1).first,
          candidate.confidence >= 0.5
        else { return nil }

        let line = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.isEmpty { return nil }

        guard seenText.insert(line.localizedLowercase).inserted
        else { return nil }
        return line
      }
      .joined(separator: " ")

    return AlbumImageRecognition(
      barcode: barcode,
      textQuery: textQuery.count > 0 ? textQuery : nil)
  }
}
