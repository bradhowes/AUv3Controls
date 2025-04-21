import SwiftUI

// Source: https://stackoverflow.com/a/56874327/629836

extension Color {

  /**
   Create new Color instance with color components taken from hex color specification. Supports

   - 3-characters (12-bit RGB) with 4 bits per channel
   - 6-characters (24-bit RGB) with 8 bits per channel
   - 8-characters (32-bit ARGB) with 8 bits per each channel

   - parameter hex: the color specification to decode
   */
  public init?(hex: String) {
    self.init(hex: Substring(hex))
  }

  /**
   Create new Color instance with color components taken from hex color specification. Supports

   - 3-characters (12-bit RGB) with 4 bits per RGB channel
   - 6-characters (24-bit RGB) with 8 bits per RGB channel
   - 8-characters (32-bit ARGB) with 8 bits per RGB channel + alpha

   - parameter hex: the color specification to decode
   */
  public init?(hex: Substring) {

    func dropPrefix(_ hex: Substring) -> Substring {
      var hex = hex
      while hex.first == " " {
        hex = hex.dropFirst()
      }
      if hex.first == "#" {
        return hex.dropFirst()
      } else if hex.first == "0" && hex.dropFirst().first == "x" {
        return hex.dropFirst(2)
      }
      return hex
    }

    let hex = String(dropPrefix(hex))
    let scanner = Scanner(string: hex)

    var int: UInt64 = 0
    guard scanner.scanHexInt64(&int) else {
      return nil
    }

    let argb: ARGB
    switch hex.count {
    case 3: argb = ARGB(255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: argb = ARGB(255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: argb = ARGB(int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default: return nil
    }

    self.init(.sRGB, red: argb.red.normalized, green: argb.green.normalized, blue: argb.blue.normalized,
              opacity: argb.alpha.normalized)
  }
}

extension String {

  /**
   Attempt to parse string contents as a color specification

   - returns: Color instance if contents is a valid color specification
   */
  public var color: Color? { Color(hex: self) }
}

private extension UInt8 {
  var normalized: Double { Double(self) / 255.0 }
}

private struct ARGB {
  let alpha: UInt8
  let red: UInt8
  let green: UInt8
  let blue: UInt8

  init(_ alpha: UInt64, _ red: UInt64, _ green: UInt64, _ blue: UInt64) {
    self.alpha = UInt8(alpha)
    self.red = UInt8(red)
    self.green = UInt8(green)
    self.blue = UInt8(blue)
  }
}
