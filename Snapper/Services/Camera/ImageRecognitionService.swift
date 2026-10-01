import Foundation
import Vision

nonisolated struct ImageRecognition: Sendable {
  let barcode: String?
  let textQuery: String?
}

nonisolated struct ImageRecognitionService: Sendable {
  func recognize(in data: Data) async throws -> ImageRecognition {
    await withTaskGroup(of: Result.self) { group in
      group.addTask {
        await detectBarcode(in: data)
      }

      group.addTask {
        await recognizeText(in: data)
      }

      var barcode: String?
      var textQuery: String?

      for await result in group {
        switch result {
        case .barcode(let value):
          barcode = value

        case .text(let value):
          textQuery = value
        }
      }

      return ImageRecognition(
        barcode: barcode,
        textQuery: textQuery,
      )
    }
  }

  private enum Result: Sendable {
    case barcode(String?)
    case text(String?)
  }

  private func detectBarcode(in data: Data) async -> Result {
    var request = DetectBarcodesRequest()
    request.symbologies = [.ean13, .ean8, .upce]

    do {
      let handler = ImageRequestHandler(data)
      let observations = try await handler.perform(request)

      let barcode =
        observations
        .sorted { $0.confidence > $1.confidence }
        .compactMap { observation -> String? in
          guard let payload = observation.payloadString else {
            return nil
          }

          return BarcodeNormalizer.digits(in: payload)
        }
        .first

      return .barcode(barcode)
    } catch {
      return .barcode(nil)
    }
  }

  private func recognizeText(in data: Data) async -> Result {
    var request = RecognizeTextRequest()
    request.recognitionLevel = .accurate

    do {
      let handler = ImageRequestHandler(data)
      let observations = try await handler.perform(request)

      var seen = Set<String>()

      let text =
        observations
        .compactMap { observation -> String? in
          guard
            let candidate = observation.topCandidates(1).first,
            candidate.confidence >= 0.5
          else { return nil }

          let line = candidate.string
            .trimmingCharacters(in: .whitespacesAndNewlines)

          if line.isEmpty { return nil }

          guard seen.insert(line.localizedLowercase).inserted else {
            return nil
          }

          return line
        }
        .joined(separator: " ")

      return .text(text.isEmpty ? nil : text)
    } catch {
      return .text(nil)
    }
  }
}
