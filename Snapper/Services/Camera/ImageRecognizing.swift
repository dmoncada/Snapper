import SwiftUI

protocol ImageRecognizing: Sendable {
  func recognize(in data: Data) async throws -> ImageRecognitionResult
}

nonisolated struct NullImageRecognizer: ImageRecognizing, Sendable {
  func recognize(in data: Data) async throws -> ImageRecognitionResult {
    ImageRecognitionResult(
      barcode: nil,
      text: nil,
    )
  }
}

nonisolated struct StubImageRecognizer: ImageRecognizing, Sendable {
  var barcode: String?
  var text: String?

  func recognize(in data: Data) async throws -> ImageRecognitionResult {
    ImageRecognitionResult(
      barcode: barcode,
      text: text,
    )
  }
}

extension ImageRecognizing where Self == NullImageRecognizer {
  static var null: Self { Self() }
}

extension ImageRecognizing where Self == StubImageRecognizer {
  static func stub(result: ImageRecognitionResult) -> Self {
    Self(barcode: result.barcode, text: result.text)
  }

  static func stub(barcode: String? = nil, text: String? = nil) -> Self {
    Self(barcode: barcode, text: text)
  }
}
