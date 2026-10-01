@preconcurrency import AVFoundation

nonisolated final class BarcodeDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate {
  private let onBarcode: @Sendable (String) -> Void

  init(onBarcode: @escaping @Sendable (String) -> Void) {
    self.onBarcode = onBarcode
  }

  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection,
  ) {
    guard
      let code =
        metadataObjects
        .compactMap({ $0 as? AVMetadataMachineReadableCodeObject })
        .compactMap(\.stringValue)
        .first
    else { return }

    onBarcode(code)
  }
}
