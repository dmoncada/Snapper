nonisolated struct ImageRecognitionResult: Sendable {
  let barcode: String?
  let text: String?
}

extension ImageRecognitionResult {
  static func barcode(_ value: String) -> Self { Self(barcode: value, text: nil) }
  static func text(_ value: String) -> Self { Self(barcode: nil, text: value) }
}
