import AVFoundation
import ComposableArchitecture
import SwiftUI

let param1 = AUParameterTree.createBoolean(withIdentifier: "Retrigger", name: "Retrigger", address: 1)
let param2 = AUParameterTree.createBoolean(withIdentifier: "Monophonic", name: "Monophonic", address: 2)
let param3 = AUParameterTree.createFloat(withIdentifier: "Volume", name: "Volume", address: 3, range: 0...100)
let param4 = AUParameterTree.createFloat(withIdentifier: "Pan", name: "Pan", address: 4, range: -50...50)

let theme = Theme()

let config3 = KnobConfig(parameter: param3, theme: theme)
let config4 = KnobConfig(parameter: param4, theme: theme)

class MockAUv3 {
  private let paramTree: AUParameterTree

  // Bindings to a state value but with a twist. We only ever use the 'setter' part of the binding when we see that
  // the AUParameter it belongs to has changed.
  private var bindings: [AUParameterAddress: Binding<Double>] = [:]

  init() {
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

  func binding(to param: AUParameterAddress, with state: Binding<Double>) -> Binding<Double> {
    self.bindings[param] = state
    // Binding getter returns the state value but the setter updates the AUParameter
    return .init(get: { state.wrappedValue }, set: { self[param] = AUValue($0) })
  }

  func binding(to param: AUParameterAddress, with state: Binding<Bool>) -> Binding<Bool> {
    // Install binding that maps between Double and Bool values
    self.bindings[param] = Binding<Double>(
      get: { state.wrappedValue ? 1.0 : 0.0 },
      set: { state.wrappedValue = $0 >= 0.5 }
    )
    // Binding getter returns the state value but the setter updates the AUParameter
    return .init(get: { state.wrappedValue }, set: { self[param] = AUValue($0 ? 1.0 : 0.0) })
  }
}

struct DualityView: View {

  var mockAUv3: MockAUv3!

  @State var store1: StoreOf<ToggleFeature>
  @State var store2: StoreOf<ToggleFeature>
  @State var store3: StoreOf<KnobFeature>
  @State var store4: StoreOf<KnobFeature>

  @State var toggle1: Bool = false
  @State var toggle2: Bool = false
  @State var slider3: Double = 0.0
  @State var slider4: Double = 0.0

  init() {
    store1 = Store(initialState: ToggleFeature.State(parameter: param1)) { ToggleFeature() }
    store2 = Store(initialState: ToggleFeature.State(parameter: param2)) { ToggleFeature() }
    store3 = Store(initialState: KnobFeature.State(config: config3)) { KnobFeature(config: config3) }
    store4 = Store(initialState: KnobFeature.State(config: config4)) { KnobFeature(config: config4) }
    self.mockAUv3 = MockAUv3()
  }

  var body: some View {
    NavigationStack {
      VStack {
        GroupBox(label: Label("AUv3Controls", systemImage: "waveform")) {
          VStack(spacing: 24) {
            HStack {
              KnobView(store: store3, config: config3)
              KnobView(store: store4, config: config4)
            }
            VStack(alignment: .leading, spacing: 12) {
              ToggleView(store: store1, theme: theme)
              ToggleView(store: store2, theme: theme)
            }
          }
        }
        GroupBox(label: Label("Mock MIDI", systemImage: "pianokeys")) {
          Slider(value: self.mockAUv3.binding(to: param3.address, with: $slider3), in: config3.range)
          Text("Volume: \(slider3)")
          Slider(value: self.mockAUv3.binding(to: param4.address, with: $slider4), in: config4.range)
          Text("Pan: \(slider4)")
          Toggle(isOn: self.mockAUv3.binding(to: param1.address, with: $toggle1)) {
            Text("Retrigger")
          }
          Toggle(isOn: self.mockAUv3.binding(to: param2.address, with: $toggle2)) {
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
  static var previews: some View {
    VStack {
      DualityView()
    }
  }
}
