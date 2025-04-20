import Foundation

extension NumberFormatter {
  public func format(value: Double) -> String { self.string(from: NSNumber(value: value)) ?? "NaN" }
  public func format(value: Float) -> String { format(value: Double(value)) }
}
