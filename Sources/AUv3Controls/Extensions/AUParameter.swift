import ComposableArchitecture
import AudioToolbox

extension AUParameter {

  /**
   Obtain a stream of value changes from a parameter, presumably changed by another entity such as a MIDI
   connection.

   - returns: 2-tuple containing a token for cancelling the observation and an AsyncStream of observed values
   */
  public func startObserving(onTermination: (@Sendable (Any) -> Void)? = nil) -> (AUParameterObserverToken, AsyncStream<AUValue>) {
    let (stream, continuation) = AsyncStream<AUValue>.makeStream()
    let observerToken = self.token(byAddingParameterObserver: { address, value in
      var lastSeen: AUValue?
      if address == self.address && value != lastSeen {
        lastSeen = value
        continuation.yield(value)
      }
    })

    continuation.onTermination = onTermination

    return (observerToken, stream)
  }
}

public extension AUParameter {
  /// - returns: a `ClosedRange` made up of the `AUParameter` min and max values
  var range: ClosedRange<AUValue> { self.minValue...self.maxValue }
}

public extension Bool {
  /// - returns: an `AUValue` of `0.0` for `false` and `1.0` for `true`
  var asValue: AUValue { self ? 1.0 : 0.0 }
}

public extension AUValue {
  /// - returns: `false` if `self` is less than `0.5` and `true` otherwise.
  var asBool: Bool { self >= 0.5 }
}

#if hasFeature(RetroactiveAttribute)
extension AUParameterObserverToken: @retroactive @unchecked Sendable {}
extension AUParameter: @retroactive @unchecked Sendable {}
#else
extension AUParameterObserverToken: @unchecked Sendable {}
extension AUParameter: @unchecked Sendable {}
#endif

