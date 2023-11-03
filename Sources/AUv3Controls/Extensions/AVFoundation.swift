import ComposableArchitecture
import AVFoundation

public extension AUParameter {

  /// Obtain a stream of value changes from a parameter, presumably changed by another entity such as MIDI.
  func startObserving(_ observerToken: inout AUParameterObserverToken?) -> AsyncStream<AUValue> {

    let (stream, continuation) = AsyncStream<AUValue>.makeStream()

    // Monitor the parameter for value changes and send them to the stream
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
  var range: ClosedRange<AUValue> { return self.minValue...self.maxValue }
}

public extension Bool {
  var asValue: AUValue { self ? 1.0 : 0.0 }
}

public extension AUValue {
  var asBool: Bool { self >= 0.5 }
}

public extension AUParameterTree {
  static func createBoolean(withIdentifier identifier: String, name: String, address: AUParameterAddress) -> AUParameter {
    createParameter(withIdentifier: identifier, name: name, address: address,
                    min: 0, max: 1, unit: .boolean, unitName: nil, valueStrings: nil,
                    dependentParameters: nil)
  }

  static func createFloat(withIdentifier identifier: String, name: String, address: AUParameterAddress,
                          range: ClosedRange<AUValue>, unit: AudioUnitParameterUnit = .generic) -> AUParameter {
    createParameter(withIdentifier: identifier, name: name, address: address,
                    min: range.lowerBound, max: range.upperBound, unit: unit, unitName: nil, valueStrings: nil,
                    dependentParameters: nil)
  }
}