import SwiftUI

struct AlbumScanStatusView: View {
  let model: AlbumScanFlowModel

  var body: some View {
    if model.isSearching {
      ProgressView("Looking up album...")
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Radius.md))
        .allowsHitTesting(false)
    } else if let message = model.message {
      VStack {
        Text(message)
          .multilineTextAlignment(.center)
        Button("Retry", systemImage: "arrow.clockwise", action: model.retry)
        Button("Scan Again", systemImage: "barcode.viewfinder", action: model.scanAgain)
      }
      .padding()
      .background(.regularMaterial, in: .rect(cornerRadius: Radius.md))
      .padding()
    }
  }
}
