@preconcurrency import AVFoundation
import Dispatch
import Foundation
import SwiftUI

actor PhotoCaptureService {
  enum CameraError: Error {
    case permissionDenied
    case rearCameraUnavailable
    case cannotAddInput
    case cannotAddOutput
    case cannotAddBarcodeOutput
    case notStarted
    case noPhotoData
  }

  nonisolated let previewSource: PreviewSource

  init() {
    previewSource = DefaultPreviewSource(session: session)
  }

  private let session = AVCaptureSession()
  private let photoOutput = AVCapturePhotoOutput()
  private let barcodeOutput = AVCaptureMetadataOutput()

  private var isConfigured = false
  private var isCapturingPhoto = false

  private var barcodeDelegate: BarcodeDelegate?
  private var barcodeContinuation: AsyncStream<String>.Continuation?
  private var barcodeStreamId: UUID?

  private var candidateBarcode: String?
  private var candidateCount = 0

  private let sessionQueue = DispatchSerialQueue(label: "PhotoCaptureService.session")
  private var capturesInProgress: [UUID: PhotoDelegate] = [:]

  // Keep blocking AVFoundation session work off the main thread.
  nonisolated var unownedExecutor: UnownedSerialExecutor {
    sessionQueue.asUnownedSerialExecutor()
  }

  func start() async throws {
    let authorized: Bool

    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      authorized = true

    case .notDetermined:
      authorized = await AVCaptureDevice.requestAccess(for: .video)

    default:
      authorized = false
    }

    guard authorized else { throw CameraError.permissionDenied }
    if session.isRunning { return }
    try ensureConfigured()
    session.startRunning()
  }

  func stop() {
    barcodeContinuation?.finish()
    barcodeContinuation = nil
    barcodeStreamId = nil

    candidateBarcode = nil
    candidateCount = 0

    if session.isRunning {
      session.stopRunning()
    }
  }

  func barcodes() -> AsyncStream<String> {
    barcodeContinuation?.finish()

    let id = UUID()
    let (stream, continuation) = AsyncStream.makeStream(
      of: String.self,
      bufferingPolicy: .bufferingNewest(1),
    )

    barcodeStreamId = id
    barcodeContinuation = continuation
    continuation.onTermination = { [weak self] _ in
      Task {
        await self?.clearBarcodeStream(id: id)
      }
    }

    return stream
  }

  private func clearBarcodeStream(id: UUID) {
    guard barcodeStreamId == id else { return }
    barcodeStreamId = nil
    barcodeContinuation = nil
  }

  private func receiveBarcode(_ payload: String) {
    guard session.isRunning, !isCapturingPhoto, let barcodeContinuation else { return }
    guard let barcode = BarcodeNormalizer.digits(in: payload) else { return }

    if candidateBarcode == barcode {
      candidateCount += 1
    } else {
      candidateBarcode = barcode
      candidateCount = 1
    }

    guard candidateCount >= 2 else { return }
    barcodeContinuation.yield(barcode)
    barcodeContinuation.finish()
    self.barcodeContinuation = nil
    barcodeStreamId = nil
  }

  private func ensureConfigured() throws {
    if isConfigured { return }

    guard
      let camera = AVCaptureDevice.default(
        .builtInWideAngleCamera,
        for: .video,
        position: .back,
      )
    else {
      throw CameraError.rearCameraUnavailable
    }

    try configureSession(camera: camera)

    isConfigured = true
  }

  private func configureSession(camera: AVCaptureDevice) throws {
    let input = try AVCaptureDeviceInput(device: camera)

    session.beginConfiguration()
    defer { session.commitConfiguration() }

    session.sessionPreset = .photo

    guard session.canAddInput(input) else {
      throw CameraError.cannotAddInput
    }

    session.addInput(input)

    guard session.canAddOutput(photoOutput) else {
      throw CameraError.cannotAddOutput
    }

    session.addOutput(photoOutput)

    guard session.canAddOutput(barcodeOutput) else {
      throw CameraError.cannotAddBarcodeOutput
    }

    session.addOutput(barcodeOutput)

    let supportedTypes = Set(barcodeOutput.availableMetadataObjectTypes)
    let filteredTypes = [AVMetadataObject.ObjectType.ean13, .ean8, .upce]
      .filter { supportedTypes.contains($0) }

    let delegate = BarcodeDelegate { [weak self] payload in
      Task {
        await self?.receiveBarcode(payload)
      }
    }

    barcodeOutput.metadataObjectTypes = filteredTypes
    barcodeOutput.setMetadataObjectsDelegate(delegate, queue: sessionQueue)
    barcodeDelegate = delegate
  }

  func takePhoto() async throws -> Data {
    guard session.isRunning else { throw CameraError.notStarted }

    isCapturingPhoto = true
    defer { isCapturingPhoto = false }

    return try await withCheckedThrowingContinuation { continuation in
      let captureId = UUID()

      let delegate = PhotoDelegate(continuation: continuation) { [weak self] in
        Task {
          await self?.finishCapture(captureId)
        }
      }

      capturesInProgress[captureId] = delegate

      photoOutput.capturePhoto(
        with: AVCapturePhotoSettings(),
        delegate: delegate,
      )
    }
  }

  private func finishCapture(_ id: UUID) {
    capturesInProgress[id] = nil
  }
}

nonisolated private final class PhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let continuation: CheckedContinuation<Data, Error>
  private let onCompletion: @Sendable () -> Void
  private var data: Data?
  private var processingError: Error?

  init(
    continuation: CheckedContinuation<Data, Error>,
    onCompletion: @escaping @Sendable () -> Void,
  ) {
    self.continuation = continuation
    self.onCompletion = onCompletion
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?,
  ) {
    processingError = error
    data = photo.fileDataRepresentation()
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
    error: Error?,
  ) {
    if let error = error ?? processingError {
      continuation.resume(throwing: error)
    } else if let data {
      continuation.resume(returning: data)
    } else {
      continuation.resume(throwing: PhotoCaptureService.CameraError.noPhotoData)
    }
    onCompletion()
  }
}

struct CameraPreview: UIViewRepresentable {
  let source: PreviewSource

  func makeUIView(context: Context) -> PreviewView {
    let view = PreviewView()
    source.connect(to: view)
    return view
  }

  func updateUIView(_ view: PreviewView, context: Context) {}

  final class PreviewView: UIView, PreviewTarget {
    override class var layerClass: AnyClass {
      AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
      layer as! AVCaptureVideoPreviewLayer
    }

    func setSession(_ session: AVCaptureSession) {
      previewLayer.session = session
      previewLayer.videoGravity = .resizeAspectFill
    }
  }
}

protocol PreviewSource: Sendable {
  @MainActor func connect(to target: PreviewTarget)
}

@MainActor protocol PreviewTarget {
  func setSession(_ session: AVCaptureSession)
}

nonisolated struct DefaultPreviewSource: PreviewSource {
  private let session: AVCaptureSession

  init(session: AVCaptureSession) {
    self.session = session
  }

  @MainActor func connect(to target: PreviewTarget) {
    target.setSession(session)
  }
}
