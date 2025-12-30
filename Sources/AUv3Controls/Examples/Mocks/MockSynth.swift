// Copyright © 2025 Brad Howes. All rights reserved.

import AVFoundation
import SwiftUI

class MockSynth {
  let paramTree: AUParameterTree

  // Duality parameters
  let retrigger: AUParameter
  let monophonic: AUParameter

  let frequency: AUParameter
  let pan: AUParameter

  // Amp envelope parameters
  let ampDelay: AUParameter
  let ampAttack: AUParameter
  let ampHold: AUParameter
  let ampDecay: AUParameter
  let ampSustain: AUParameter
  let ampRelease: AUParameter

  // Mod envelope parameters
  let modDelay: AUParameter
  let modAttack: AUParameter
  let modHold: AUParameter
  let modDecay: AUParameter
  let modSustain: AUParameter
  let modRelease: AUParameter

  // Bindings to a state value but with a twist. We only ever use the 'setter' part of the binding when we see that
  // the AUParameter it belongs to has changed.
  private var bindings: [AUParameterAddress: Binding<Double>] = [:]

  init() {
    retrigger = AUParameterTree.createBoolean(withIdentifier: "Retrigger", name: "Retrigger", address: 1)
    monophonic = AUParameterTree.createBoolean(withIdentifier: "Monophonic", name: "Monophonic", address: 2)
    frequency = AUParameterTree.createFloat(withIdentifier: "Frequency", name: "Frequency", address: 3, range: 10...20_000,
                                            unit: .hertz, logScale: true)
    pan = AUParameterTree.createFloat(withIdentifier: "Pan", name: "Pan", address: 4, range: -50...50)

    var parameterBase: AUParameterAddress = 100
    ampDelay = AUParameterTree.createParameter(
      withIdentifier: "AMP DELAY",
      name: "Delay",
      address: parameterBase + 0,
      min: 0.0,
      max: 2.0,
      unit: .seconds,
      unitName: nil,
      flags: [.flag_DisplayLogarithmic],
      valueStrings: nil,
      dependentParameters: nil
    )

    ampAttack = AUParameterTree.createParameter(
      withIdentifier: "AMP ATTACK",
      name: "Attack",
      address: parameterBase + 1,
      min: 0.0,
      max: 5.0,
      unit: .seconds,
      unitName: nil,
      flags: [.flag_DisplayLogarithmic],
      valueStrings: nil,
      dependentParameters: nil
    )

    ampHold = AUParameterTree.createParameter(
      withIdentifier: "AMP HOLD",
      name: "Hold",
      address: parameterBase + 2,
      min: 0.0,
      max: 5,
      unit: .seconds,
      unitName: nil,
      flags: [.flag_DisplayLogarithmic],
      valueStrings: nil,
      dependentParameters: nil
    )

    ampDecay = AUParameterTree.createParameter(
      withIdentifier: "AMP DECAY",
      name: "Decay",
      address: parameterBase + 3,
      min: 0.0,
      max: 5.0,
      unit: .seconds,
      unitName: nil,
      flags: [.flag_DisplayLogarithmic],
      valueStrings: nil,
      dependentParameters: nil
    )

    ampSustain = AUParameterTree.createParameter(
      withIdentifier: "AMP SUSTAIN",
      name: "Sustain",
      address: parameterBase + 4,
      min: 0.0,
      max: 100.0,
      unit: .percent,
      unitName: nil,
      flags: [],
      valueStrings: nil,
      dependentParameters: nil
    )

    ampRelease = AUParameterTree.createParameter(
      withIdentifier: "AMP RELEASE",
      name: "Release",
      address: parameterBase + 5,
      min: 0.0,
      max: 10.0,
      unit: .seconds,
      unitName: nil,
      flags: [.flag_DisplayLogarithmic],
      valueStrings: nil,
      dependentParameters: nil
    )

    parameterBase = 200
    modDelay = AUParameterTree.createParameter(
      withIdentifier: "MOD DELAY",
      name: "Delay",
      address: parameterBase + 0,
      min: 0.0,
      max: 2.0,
      unit: .seconds,
      unitName: nil,
      flags: [.flag_DisplayLogarithmic],
      valueStrings: nil,
      dependentParameters: nil
    )

    modAttack = AUParameterTree.createParameter(
      withIdentifier: "MOD ATTACK",
      name: "Attack",
      address: parameterBase + 1,
      min: 0.0,
      max: 5.0,
      unit: .seconds,
      unitName: nil,
      flags: [.flag_DisplayLogarithmic],
      valueStrings: nil,
      dependentParameters: nil
    )

    modHold = AUParameterTree.createParameter(
      withIdentifier: "MOD HOLD",
      name: "Hold",
      address: parameterBase + 2,
      min: 0.0,
      max: 5,
      unit: .seconds,
      unitName: nil,
      flags: [.flag_DisplayLogarithmic],
      valueStrings: nil,
      dependentParameters: nil
    )

    modDecay = AUParameterTree.createParameter(
      withIdentifier: "MOD DECAY",
      name: "Decay",
      address: parameterBase + 3,
      min: 0.0,
      max: 5.0,
      unit: .seconds,
      unitName: nil,
      flags: [.flag_DisplayLogarithmic],
      valueStrings: nil,
      dependentParameters: nil
    )

    modSustain = AUParameterTree.createParameter(
      withIdentifier: "MOD SUSTAIN",
      name: "Sustain",
      address: parameterBase + 4,
      min: 0.0,
      max: 100.0,
      unit: .percent,
      unitName: nil,
      flags: [],
      valueStrings: nil,
      dependentParameters: nil
    )

    modRelease = AUParameterTree.createParameter(
      withIdentifier: "MOD RELEASE",
      name: "Release",
      address: parameterBase + 5,
      min: 0.0,
      max: 10.0,
      unit: .seconds,
      unitName: nil,
      flags: [.flag_DisplayLogarithmic],
      valueStrings: nil,
      dependentParameters: nil
    )

    self.paramTree = AUParameterTree.createTree(withChildren: [
      frequency,
      pan,
      retrigger,
      monophonic,
      ampDelay,
      ampAttack,
      ampHold,
      ampDecay,
      ampSustain,
      ampRelease,
      modDelay,
      modAttack,
      modHold,
      modDecay,
      modSustain,
      modRelease
    ])

    self.paramTree.implementorValueObserver = { parameter, value in
      if let binding = self.bindings[parameter.address] {
        DispatchQueue.main.async {
          binding.wrappedValue = Double(value)
        }
      }
    }
  }

  private subscript(_ index: AUParameterAddress) -> AUValue {
    get { paramTree.parameter(withAddress: index)?.value ?? 0.0 }
    set { paramTree.parameter(withAddress: index)?.setValue(newValue, originator: nil) }
  }

  func binding(to address: AUParameterAddress, with state: Binding<Double>) -> Binding<Double> {
    guard let param = self.paramTree.parameter(withAddress: address) else {
      fatalError("invalid parameter address")
    }

    self.bindings[address] = state

    // Binding getter returns the state value but the setter updates the AUParameter
    return .init(
      get: { state.wrappedValue },
      set: { param.setValue(AUValue($0), originator: nil) }
    )
  }

  func binding(to address: AUParameterAddress, with state: Binding<Bool>) -> Binding<Bool> {
    guard let param = self.paramTree.parameter(withAddress: address) else {
      fatalError("invalid parameter address")
    }

    // Install binding that maps between Double and Bool values
    self.bindings[address] = Binding<Double>(
      get: { state.wrappedValue ? 1.0 : 0.0 },
      set: { state.wrappedValue = $0 >= 0.5 }
    )

    // Binding getter returns the state value but the setter updates the AUParameter
    return .init(
      get: { state.wrappedValue },
      set: { param.setValue(AUValue($0 ? 1.0 : 0.0), originator: nil) }
    )
  }
}
