import AVFoundation
import ComposableArchitecture
import SwiftUI

class MockAUv3 {
  let theme: Theme

  let paramTree: AUParameterTree
  let param1: AUParameter // boolean parameter
  let param2: AUParameter // boolean parameter
  let param3: AUParameter // float parameter
  let param4: AUParameter // float parameter

  let config3: KnobConfig
  let config4: KnobConfig

  // Bindings to a state value but with a twist. We only ever use the 'setter' part of the binding when we see that
  // the AUParameter it belongs to has changed.
  private var bindings: [AUParameterAddress: Binding<Double>] = [:]

  init() {
    self.theme = Theme()

    let param1 = AUParameterTree.createBoolean(withIdentifier: "Retrigger", name: "Retrigger", address: 1)
    self.param1 = param1
    let param2 = AUParameterTree.createBoolean(withIdentifier: "Monophonic", name: "Monophonic", address: 2)
    self.param2 = param2
    let param3 = AUParameterTree.createFloat(withIdentifier: "Volume", name: "Volume", address: 3, range: 0...100)
    self.param3 = param3
    let param4 = AUParameterTree.createFloat(withIdentifier: "Pan", name: "Pan", address: 4, range: -50...50)
    self.param4 = param4

    self.config3 = KnobConfig(parameter: param3, theme: theme)
    self.config4 = KnobConfig(parameter: param4, theme: theme)

    self.paramTree = AUParameterTree.createTree(withChildren: [param1, param2, param3, param4])

    self.paramTree.implementorValueObserver = { parameter, value in
      if let binding = self.bindings[parameter.address] {
        binding.wrappedValue = Double(value)
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

  var param1: AUParameter { mockAUv3.param1 }
  var param2: AUParameter { mockAUv3.param2 }
  var param3: AUParameter { mockAUv3.param3 }
  var param4: AUParameter { mockAUv3.param4 }

  var config3: KnobConfig { mockAUv3.config3 }
  var config4: KnobConfig { mockAUv3.config4 }

  init() {
    let mockAUv3 = MockAUv3()

    self.mockAUv3 = mockAUv3
    self.store1 = .init(initialState: ToggleFeature.State(parameter: mockAUv3.param1)) { ToggleFeature() }
    self.store2 = .init(initialState: ToggleFeature.State(parameter: mockAUv3.param2)) { ToggleFeature() }

    self.store3 = .init(initialState: KnobFeature.State(config: mockAUv3.config3)) {
      KnobFeature(config: mockAUv3.config3) }
    self.store4 = .init(initialState: KnobFeature.State(config: mockAUv3.config4)) {
      KnobFeature(config: mockAUv3.config4) }
  }

  var body: some View {
    NavigationStack {
      VStack {
        GroupBox(label: Label("AUv3Controls", systemImage: "waveform")) {
          VStack(spacing: 24) {
            HStack(spacing: 18) {
              KnobView(store: store3, config: mockAUv3.config3)
              KnobView(store: store4, config: mockAUv3.config4)
            }
            VStack(alignment: .leading, spacing: 12) {
              ToggleView(store: store1, theme: mockAUv3.theme)
              ToggleView(store: store2, theme: mockAUv3.theme)
            }
          }
        }
        GroupBox(label: Label("Mock MIDI", systemImage: "pianokeys")) {
          Slider(value: mockAUv3.binding(to: param3.address, with: $slider3), in: config3.range)
          HStack {
            Button {
              param3.setValue(0.0, originator: nil)
            } label: {
              Text("Min")
            }
            Spacer()
            Text("Volume: \(String(format: "%6.2f", slider3))")
            Spacer()
            Button {
              param3.setValue(100.0, originator: nil)
            } label: {
              Text("Max")
            }
          }
          Slider(value: mockAUv3.binding(to: param4.address, with: $slider4), in: config4.range)
          HStack {
            Button {
              param4.setValue(-50.0, originator: nil)
            } label: {
              Text("Min")
            }
            Spacer()
            Text("Pan: \(String(format: "%6.2f", slider4))")
            Spacer()
            Button {
              param4.setValue(50.0, originator: nil)
            } label: {
              Text("Max")
            }
          }
          Toggle(isOn: mockAUv3.binding(to: param1.address, with: $toggle1)) {
            Text("Retrigger")
          }
          Toggle(isOn: mockAUv3.binding(to: param2.address, with: $toggle2)) {
            Text("Monophonic")
          }
        }
        .padding()
      }
      .navigationTitle(Text("Duality"))
    }
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
