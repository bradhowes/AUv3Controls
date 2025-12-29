// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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

extension Color {

  /**
   Look for a color asset with a given name, resulting in `None` if the named asset was not found.

   - parameter named: the name to look for
   - parameter bundle: where to look for the asset
   */
  init?(named name: String, bundle: Bundle = .main) {
#if canImport(UIKit)
    guard let color = UIColor(named: name, in: bundle, compatibleWith: nil) else {
      return nil
    }
    self = .init(color)
#elseif canImport(AppKit)
    guard let color = NSColor(named: NSColor.Name(name), bundle: bundle) else {
      return nil
    }
    self = .init(color)
#else
    return nil
#endif
    print("Color", self.description)
  }

  /// Convenience boolean check for existence of a color asset.
  static func assetExists(named name: String, bundle: Bundle = .main) -> Bool {
#if canImport(UIKit)
    return UIColor(named: name, in: bundle, compatibleWith: nil) != nil
#elseif canImport(AppKit)
    return NSColor(named: NSColor.Name(name), bundle: bundle) != nil
#else
    return false
#endif
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

#if canImport(UIKit)
public typealias NativeColor = UIColor
#elseif canImport(AppKit)
public typealias NativeColor = NSColor
#endif

public extension NativeColor {

  func mix(with target: NativeColor, amount: CGFloat) -> Self {
    var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
    var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

    guard let us = self.usingColorSpace(.sRGB) else { return self }
    us.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)

    guard let tgt = target.usingColorSpace(.sRGB) else { return self }
    tgt.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

    return Self(
      red: r1 * (1.0 - amount) + r2 * amount,
      green: g1 * (1.0 - amount) + g2 * amount,
      blue: b1 * (1.0 - amount) + b2 * amount,
      alpha: a1
    )
  }
}

public extension Color {
  func mix_shim(with target: Color, by amount: CGFloat) -> Color {
    Color(NativeColor(self).mix(with: NativeColor(target), amount: amount))
  }
}
