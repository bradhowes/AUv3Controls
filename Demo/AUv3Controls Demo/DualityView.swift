// Copyright © 2025 Brad Howes. All rights reserved.

import AUv3Controls
import AVFoundation
import ComposableArchitecture
import SwiftUI

class MockAUv3 {
  let paramTree: AUParameterTree
  let param1: AUParameter // boolean parameter
  let param2: AUParameter // boolean parameter
  let param3: AUParameter // float parameter
  let param4: AUParameter // float parameter

  // Bindings to a state value but with a twist. We only ever use the 'setter' part of the binding when we see that
  // the AUParameter it belongs to has changed.
  private var bindings: [AUParameterAddress: Binding<Double>] = [:]

  init() {
    let param1 = AUParameterTree.createBoolean(withIdentifier: "Retrigger", name: "Retrigger", address: 1)
    self.param1 = param1
    let param2 = AUParameterTree.createBoolean(withIdentifier: "Monophonic", name: "Monophonic", address: 2)
    self.param2 = param2
    let param3 = AUParameterTree.createFloat(
      withIdentifier: "Frequency",
      name: "Frequency",
      address: 3,
      range: 10...20_000,
      unit: .hertz,
      logScale: true
    )
    self.param3 = param3
    let param4 = AUParameterTree.createFloat(withIdentifier: "Pan", name: "Pan", address: 4, range: -50...50)
    self.param4 = param4

    self.paramTree = AUParameterTree.createTree(withChildren: [param1, param2, param3, param4])
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

struct DualityView: View {
  let mockAUv3: MockAUv3
  
  @State var store1: StoreOf<ToggleFeature>
  @State var store2: StoreOf<ToggleFeature>
  @State var store3: StoreOf<KnobFeature>
  @State var store4: StoreOf<KnobFeature>

  @State var toggle1: Bool = false
  @State var toggle2: Bool = false
  @State var slider3: Double = 0.0
  @State var slider4: Double = 0.0

  @Environment(\.colorScheme) private var colorScheme

  init() {
    let mockAUv3 = MockAUv3()
    self.mockAUv3 = mockAUv3
    self.store1 = .init(initialState: ToggleFeature.State(parameter: mockAUv3.param1)) { ToggleFeature() }
    self.store2 = .init(initialState: ToggleFeature.State(parameter: mockAUv3.param2)) { ToggleFeature() }
    self.store3 = .init(initialState: KnobFeature.State(parameter: mockAUv3.param3)) {
      KnobFeature(parameter: mockAUv3.param3)
    }
    self.store4 = .init(initialState: KnobFeature.State(parameter: mockAUv3.param4)) {
      KnobFeature(parameter: mockAUv3.param4)
    }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          GroupBox(label: Label("AUv3Controls", systemImage: "waveform")) {
            VStack(spacing: 24) {
              HStack(spacing: 18) {
                KnobView(store: store3)
                KnobView(store: store4)
              }
              .frame(height: 120)
              .offset(y: 12)
              VStack(alignment: .leading, spacing: 12) {
                ToggleView(store: store1) { Text(store1.displayName) }
                ToggleView(store: store2) { Text(store2.displayName) }
              }
            }
          }
          GroupBox(label: Label("Mock MIDI", systemImage: "pianokeys")) {
            Slider(value: mockAUv3.binding(to: mockAUv3.param3.address, with: $slider3), in: mockAUv3.param3.range)
            HStack {
              Button {
                mockAUv3.param3.setValue(10.0, originator: nil)
              } label: {
                Text("Min")
              }
              Spacer()
              Text("Volume: \(String(format: "%6.2f", slider3))")
              Spacer()
              Button {
                mockAUv3.param3.setValue(20_000.0, originator: nil)
              } label: {
                Text("Max")
              }
            }
            Slider(value: mockAUv3.binding(to: mockAUv3.param4.address, with: $slider4), in: mockAUv3.param4.range)
            HStack {
              Button {
                mockAUv3.param4.setValue(-50.0, originator: nil)
              } label: {
                Text("Min")
              }
              Spacer()
              Text("Pan: \(String(format: "%6.2f", slider4))")
              Spacer()
              Button {
                mockAUv3.param4.setValue(50.0, originator: nil)
              } label: {
                Text("Max")
              }
            }
            Toggle(isOn: mockAUv3.binding(to: mockAUv3.param1.address, with: $toggle1)) {
              Text("Retrigger")
            }
            Toggle(isOn: mockAUv3.binding(to: mockAUv3.param2.address, with: $toggle2)) {
              Text("Monophonic")
            }
          }
        }
      }
      .navigationTitle(Text("Duality"))
    }
    .auv3ControlsTheme(.init(colorScheme: colorScheme, prefix: "duality", bundle: Bundle.main))
    .knobValueEditor()
  }
}

struct DualityViewPreview: PreviewProvider {
  @MainActor
  static var previews: some View {
    VStack {
      DualityView()
    }
  }
}
