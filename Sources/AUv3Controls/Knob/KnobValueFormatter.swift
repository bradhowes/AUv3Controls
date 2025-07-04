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

    /**
     Create new formatter that shows a max number of significant digits

     - parameter significantDigits: number of significant digits to show
     - parameter suffix: the suffix to append to the formatted value
     */
    init(significantDigits: ClosedRange<Int>, suffix: String) {
      self.formatter = .init().precision(.significantDigits(significantDigits))
      self.suffix = suffix
    }

    /**
     Format a floating-point value into a string representation.

     - parameter value: the value to format
     - parameter withSuffix: the units suffix to append
     - returns: the formatted value
     */
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
    FloatingPointFormatStyle<Double>()
      .grouping(.never)
      .precision(.significantDigits(1...6))
      .format(value)
  }

  /**
   Createa a general-purpose value formatter.

   - parameter significantDigits: number of significant digits
   - parameter suffix: the units suffix to append to the formatted value
   - returns: new ``KnobValueFormatter``
   */
  public static func general(_ significantDigits: ClosedRange<Int> = 1...2, suffix: String = "") -> Self {
    Self([significantDigits], suffixes: [suffix])
  }
  /**
   Formatter for percentages

   - parameter significantDigits: the number of digits to the right of the decimal point
   - returns: new ``KnobValueFormatter``
   */
  public static func percentage(_ significantDigits: ClosedRange<Int> = 1...3) -> Self {
    Self([significantDigits], suffixes: ["%"])
  }

  /**
   Formatter for time durations in seconds.

   - parameter significantDigits: the number of digits to the right of the decimal point
   - parameter suffix: the text to append to the formatted value
   - returns: new ``KnobValueFormatter``
   */
  public static func duration(_ significantDigits: ClosedRange<Int> = 1...3, suffix: String = "s") -> Self {
    Self([significantDigits], suffixes: [suffix])
  }

  /**
   Formatter for time durations in milliseconods or seconds depending on value being formatted.

   - parameter millisecondsSigDigits: the number of digits to the right of the decimal point for milliseconds values
   - parameter secondsSigDigits: the number of digits to the right of the decimal point for seconds values
   - returns: new ``KnobValueFormatter``
   */
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

   - parameter herzSigDigits: the number of digits to the right of the decimal point if value < 1000
   - parameter kiloSigDigits: the number of digits to the right of the decimal point if value >= 1000
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

  /**
   Equality comparison between two formatters.

   - parameter lhs: the first formatter to compare
   - parameter rhs: the second formatter to compare
   - returns: `true` if the instances are the same
   */
  public static func == (lhs: KnobValueFormatter, rhs: KnobValueFormatter) -> Bool {
    lhs.formatters == rhs.formatters
  }
}

extension KnobValueFormatter {

  /**
   Obtain a formatter for a given `AudioUnitParameterUnit` value.

   - parameter unit: the `AudioUnitParameterUnit` to use
   - returns: the corresponding formatter
   */
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
