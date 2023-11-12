import SwiftUI

// Source: https://stackoverflow.com/a/56874327/629836

extension Color {

  /**
   Create new Color instance with color components taken from hex color specification. Supports

   - 3-characters (12-bit RGB) with 4 bits per RGB channel
   - 6-characters (24-bit RGB) with 8 bits per RGB channel
   - 8-characters (32-bit ARGB) with 8 bits per RGB channel + alpha

   - parameter hex: the color specification to decode
   */
  init(hex: String) {
    self.init(hex: Substring(hex))
  }

  /**
   Create new Color instance with color components taken from hex color specification. Supports

   - 3-characters (12-bit RGB) with 4 bits per RGB channel
   - 6-characters (24-bit RGB) with 8 bits per RGB channel
   - 8-characters (32-bit ARGB) with 8 bits per RGB channel + alpha

   - parameter hex: the color specification to decode
   */
  init(hex: Substring) {

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
      self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
      return
    }

    let alpha, red, green, blue: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (alpha, red, green, blue) = (255, 0, 0, 0)
    }

    self.init(.sRGB,
              red: Double(red) / 255,
              green: Double(green) / 255,
              blue: Double(blue) / 255,
              opacity: Double(alpha) / 255)
  }
}
