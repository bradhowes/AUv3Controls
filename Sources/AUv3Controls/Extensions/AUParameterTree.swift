// Copyright © 2025 Brad Howes. All rights reserved.

import AudioToolbox
import ComposableArchitecture

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
  static func createFloat(
    withIdentifier identifier: String,
    name: String,
    address: AUParameterAddress,
    range: ClosedRange<AUValue>,
    unit: AudioUnitParameterUnit = .generic,
    logScale: Bool = false
  ) -> AUParameter {
    let flags: AudioUnitParameterOptions = logScale ? [.flag_DisplayLogarithmic, .flag_CanRamp] : [.flag_CanRamp]
    return createParameter(withIdentifier: identifier, name: name, address: address,
                           min: range.lowerBound, max: range.upperBound, unit: unit, unitName: nil,
                           flags: flags, valueStrings: nil, dependentParameters: nil)
  }
}
