import ComposableArchitecture
import AVFoundation

public extension AUParameter {

  /**
   Obtain a stream of value changes from a parameter, presumably changed by another entity such as a MIDI
   connection.
   
   - returns: 2-tuple containing a token for cancelling the observation and an AsyncStream of observed values
   */
  func startObserving() -> (AUParameterObserverToken, AsyncStream<AUValue>) {
    let (stream, continuation) = AsyncStream<AUValue>.makeStream()

    let displayName = self.displayName
    let observerToken = self.token(byAddingParameterObserver: { address, value in
      var lastSeen: AUValue?
      if address == self.address && value != lastSeen {
        lastSeen = value
        Logger.shared.log("\(displayName) observed \(value)")
        continuation.yield(value)
      }
    })

    continuation.onTermination = { value in
      Logger.shared.log("\(displayName) continuation terminating \(value)")
    }

    return (observerToken, stream)
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
  static func createBoolean(withIdentifier identifier: String, name: String,
                            address: AUParameterAddress) -> AUParameter {
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
