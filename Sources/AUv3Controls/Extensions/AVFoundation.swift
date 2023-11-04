import ComposableArchitecture
import AVFoundation

public extension AUParameter {

  /// Obtain a stream of value changes from a parameter, presumably changed by another entity such as a MIDI
  /// connection.
  func startObserving(_ observerToken: inout AUParameterObserverToken?) -> AsyncStream<AUValue> {

    let (stream, continuation) = AsyncStream<AUValue>.makeStream()

    // Monitor the parameter for value changes to itself and send them to the stream
    let token = self.token(byAddingParameterObserver: { address, value in
      if address == self.address {
        continuation.yield(value)
      }
    })

    // When the stream is torn down remove the observations. NOTE: we are not updating the state to nil out the
    // `observerToken` but the view should be gone anyway.
    continuation.onTermination = { @Sendable _ in
      self.removeParameterObserver(token)
    }

    // Record the observation token in the view state so to keep from seeing our own updates.
    observerToken = token

    return stream
  }
}

public extension AUParameter {

  /// Returns a `ClosedRange` made up of the `AUParameter` min and max values
  var range: ClosedRange<AUValue> { return self.minValue...self.maxValue }
}

public extension Bool {
  /// Returns an `AUValue` of `0.0` for `false` and `1.0` for `true`
  var asValue: AUValue { self ? 1.0 : 0.0 }
}

public extension AUValue {
  /// Returns `false` if `self` is less than `0.5` and `true` otherwise.
  var asBool: Bool { self >= 0.5 }
}

public extension AUParameterTree {

  /**
   Helper function that creates an `AUParameter` for a boolean value.

   - parameter identifier: the unique identifier for the parameter
   - parameter name: the display name for the parameter
   - parameter address: the unique address for the parameter
   - returns: new `AUParameter`
   */
  static func createBoolean(withIdentifier identifier: String, name: String, address: AUParameterAddress) -> AUParameter {
    createParameter(withIdentifier: identifier, name: name, address: address,
                    min: 0, max: 1, unit: .boolean, unitName: nil, valueStrings: nil,
                    dependentParameters: nil)
  }

  /**
   Helper function that creates an `AUParameter` with a ClosedRange to describe the minimum and maximum values that the
   parameter can take.

   - parameter identifier: the unique identifier for the parameter
   - parameter name: the display name for the parameter
   - parameter address: the unique address for the parameter
   - parameter range: the bounds of the parameter
   - parameter unit: the value unit of the parameter
   - returns: new `AUParameter`
   */
  static func createFloat(withIdentifier identifier: String, name: String, address: AUParameterAddress,
                          range: ClosedRange<AUValue>, unit: AudioUnitParameterUnit = .generic) -> AUParameter {
    createParameter(withIdentifier: identifier, name: name, address: address,
                    min: range.lowerBound, max: range.upperBound, unit: unit, unitName: nil, valueStrings: nil,
                    dependentParameters: nil)
  }
}
