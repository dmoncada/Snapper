import Foundation

nonisolated enum BarcodeNormalizer {
  static func digits(in payload: String) -> String? {
    let digits = String(payload.filter { "0" <= $0 && $0 <= "9" })
    return digits.count >= 8 ? digits : nil
  }
}
