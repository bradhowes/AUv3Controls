// Copyright © 2025 Brad Howes. All rights reserved.

import AudioToolbox
import Foundation

/**
 General protocol for formatting a parameter value, whether for display or for editing. The former may have a suffix
 attached to the formatted value while the latter never does.
 */
public protocol KnobValueFormattingProvider: Equatable {

  func forDisplay(_ value: Double) -> String

  func forEditing(_ value: Double) -> String
}

/**
 Value formatters for a knob when it needs to show the current setting. This is a bit convoluted in order to support
 the case where we want different units depending on the value being formatted, such as `frequency` or `seconds`.
 */
public struct KnobValueFormatter: Equatable, Sendable, KnobValueFormattingProvider {

  struct Formatter: Equatable {
    let formatter: FloatingPointFormatStyle<Double>
    let suffix: String

    init(significantDigits: ClosedRange<Int>, suffix: String) {
      self.formatter = .init().precision(.significantDigits(significantDigits))
      self.suffix = suffix
    }

    func format(_ value: Double, withSuffix: Bool = true) -> String {
      self.formatter.format(value) + (withSuffix ? suffix : "")
    }
  }

  typealias Proc = @Sendable (Array<Formatter>, Bool, Double) -> String

  let formatters: [Formatter]
  let proc: Proc

  internal init(
    _ significantDigits: [ClosedRange<Int>] = [1...3],
    suffixes: [String] = [""],
    proc: Proc? = nil
  ) {
    let formatters: [Formatter] = zip(significantDigits, suffixes).map { .init(significantDigits: $0.0, suffix: $0.1) }
    self.formatters = formatters
    if let proc {
      self.proc = proc
    } else {
      self.proc = { formatters, withSuffix, value in
        formatters[0].format(value, withSuffix: withSuffix)
      }
    }
  }

  /**
   Format a value into a string representation for displaying in view.

   - parameter value: the value to convert
   - returns: the textual representation
   */
  public func forDisplay(_ value: Double) -> String { proc(formatters, true, value) }

  /**
   Format a value into a string representation for editing in text field. Show more digits and omit any suffix.

   - parameter value: the value to convert
   - returns: the textual representation
   */
  public func forEditing(_ value: Double) -> String {
    FloatingPointFormatStyle<Double>().precision(.significantDigits(1...6)).format(value)
  }

  public static func general(_ significantDigits: ClosedRange<Int> = 1...2, suffix: String = "") -> Self {
    Self([significantDigits], suffixes: [suffix])
  }
  /**
   Formatter for percentages

   - parameter fractionDigits: the number of digits to the right of the decimal point
   - returns: a formatter
   */
  public static func percentage(_ significantDigits: ClosedRange<Int> = 1...3) -> Self {
    Self([significantDigits], suffixes: ["%"])
  }

  /**
   Formatter for durations in time

   - parameter fractionDigits: the number of digits to the right of the decimal point
   - parameter suffix: the text to append to the formatted value
   - returns: a formatter
   */
  public static func duration(_ significantDigits: ClosedRange<Int> = 1...3, suffix: String = "s") -> Self {
    Self([significantDigits], suffixes: [suffix])
  }

  public static func seconds(
    millisecondsSigDigits: ClosedRange<Int> = 1...3,
    secondsSigDigits: ClosedRange<Int> = 1...3
  ) -> Self {
    return Self([millisecondsSigDigits, secondsSigDigits], suffixes: ["ms", "s"]) { formatters, withSuffix, value in
      value < 1.0 ?
      formatters[0].format(value * 1000.0, withSuffix: withSuffix) :
      formatters[1].format(value, withSuffix: withSuffix)
    }
  }

  /**
   Formatter for frequencies

   - parameter herzFractionDigits: the number of digits to the right of the decimal point if value < 1000
   - parameter kiloFractionDigits: the number of digits to the right of the decimal point if value >= 1000
   - returns: a formatter
   */
  public static func frequency(
    herzSigDigits: ClosedRange<Int> = 1...2,
    kiloSigDigits: ClosedRange<Int> = 1...3
  ) -> Self {
    return Self([herzSigDigits, kiloSigDigits], suffixes: [" Hz", "kHz"]) { formatters, withSuffix, value in
      value < 1000.0 ?
      formatters[0].format(value, withSuffix: withSuffix) :
      formatters[1].format(value / 1000.0, withSuffix: withSuffix)
    }
  }

  public static func == (lhs: KnobValueFormatter, rhs: KnobValueFormatter) -> Bool {
    lhs.formatters == rhs.formatters
  }
}

extension KnobValueFormatter {

  public static func `for`(_ unit: AudioUnitParameterUnit) -> Self {
    switch unit {
    case .percent: return .percentage()
    case .seconds: return .seconds()
    case .phase, .degrees: return .general(suffix: "°")
    case .rate: return .general(suffix: "x")
    case .hertz: return .frequency()
    case .cents, .absoluteCents: return .general(suffix: " cents")
    case .decibels: return .general(suffix: " dB")
    case .BPM: return .general(suffix: " BPM")
    case .milliseconds: return .duration(suffix: "ms")
    default: return .general()
    }
  }
}
