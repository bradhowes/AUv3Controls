// Copyright © 2025 Brad Howes. All rights reserved.

import AVFoundation
import ComposableArchitecture
import SwiftUI

public struct DualityView: View {
  private let mockAUv3: MockAUv3

  @State private var retrigger: StoreOf<ToggleFeature>
  @State private var monophonic: StoreOf<ToggleFeature>
  @State private var frequency: StoreOf<KnobFeature>
  @State private var pan: StoreOf<KnobFeature>

  @State private var retriggerToggle: Bool = false
  @State private var monophonicToggle: Bool = false
  @State private var frequencySlider: Double = 0.0
  @State private var panSlider: Double = 0.0

  @Environment(\.colorScheme) private var colorScheme

  public init() {
    let mockAUv3 = MockAUv3()
    self.mockAUv3 = mockAUv3
    self.retrigger = .init(initialState: ToggleFeature.State(parameter: mockAUv3.retrigger)) { ToggleFeature() }
    self.monophonic = .init(initialState: ToggleFeature.State(parameter: mockAUv3.monophonic)) { ToggleFeature() }
    self.frequency = .init(initialState: KnobFeature.State(parameter: mockAUv3.frequency)) { KnobFeature() }
    self.pan = .init(initialState: KnobFeature.State(parameter: mockAUv3.pan)) { KnobFeature() }
  }

  public var body: some View {
    NavigationStack {
      VStack {
        GroupBox(label: Label("AUv3Controls", systemImage: "waveform")) {
          VStack(spacing: 24) {
            HStack(spacing: 18) {
              KnobView(store: frequency)
              KnobView(store: pan)
            }
            .frame(height: 120)
            VStack(alignment: .leading, spacing: 12) {
              ToggleView(store: retrigger) { Text(retrigger.displayName) }
              ToggleView(store: monophonic) { Text(monophonic.displayName) }
            }
          }
        }
        GroupBox(label: Label("Mock MIDI", systemImage: "pianokeys")) {
          Slider(value: mockAUv3.binding(to: mockAUv3.frequency.address, with: $frequencySlider), in: mockAUv3.frequency.range)
          HStack {
            Button {
              mockAUv3.frequency.setValue(10.0, originator: nil)
            } label: {
              Text("Min")
            }
            Spacer()
            Text("Volume: \(String(format: "%6.2f", frequencySlider))")
            Spacer()
            Button {
              mockAUv3.frequency.setValue(20_000.0, originator: nil)
            } label: {
              Text("Max")
            }
          }
          Slider(value: mockAUv3.binding(to: mockAUv3.pan.address, with: $panSlider), in: mockAUv3.pan.range)
          HStack {
            Button {
              mockAUv3.pan.setValue(-50.0, originator: nil)
            } label: {
              Text("Min")
            }
            Spacer()
            Text("Pan: \(String(format: "%6.2f", panSlider))")
            Spacer()
            Button {
              mockAUv3.pan.setValue(50.0, originator: nil)
            } label: {
              Text("Max")
            }
          }
          Toggle(isOn: mockAUv3.binding(to: mockAUv3.retrigger.address, with: $retriggerToggle)) {
            Text("Retrigger")
          }
          Toggle(isOn: mockAUv3.binding(to: mockAUv3.monophonic.address, with: $monophonicToggle)) {
            Text("Monophonic")
          }
        }
        .padding()
      }
      .navigationTitle(Text("Duality"))
    }
    .auv3ControlsTheme(Theme(colorScheme: colorScheme))
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
