// Copyright © 2025 Brad Howes. All rights reserved.

import AVFoundation
import ComposableArchitecture
import SwiftUI

public struct DualityView: View {
  private let synth = MockSynth()

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
    retrigger = .init(initialState: ToggleFeature.State(parameter: synth.retrigger)) { ToggleFeature() }
    monophonic = .init(initialState: ToggleFeature.State(parameter: synth.monophonic)) { ToggleFeature() }
    frequency = .init(initialState: KnobFeature.State(parameter: synth.frequency)) { KnobFeature() }
    pan = .init(initialState: KnobFeature.State(parameter: synth.pan)) { KnobFeature() }
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
          Slider(value: synth.binding(to: synth.frequency.address, with: $frequencySlider), in: synth.frequency.range)
          HStack {
            Button {
              synth.frequency.setValue(10.0, originator: nil)
            } label: {
              Text("Min")
            }
            Spacer()
            Text("Volume: \(String(format: "%6.2f", frequencySlider))")
            Spacer()
            Button {
              synth.frequency.setValue(20_000.0, originator: nil)
            } label: {
              Text("Max")
            }
          }
          Slider(value: synth.binding(to: synth.pan.address, with: $panSlider), in: synth.pan.range)
          HStack {
            Button {
              synth.pan.setValue(-50.0, originator: nil)
            } label: {
              Text("Min")
            }
            Spacer()
            Text("Pan: \(String(format: "%6.2f", panSlider))")
            Spacer()
            Button {
              synth.pan.setValue(50.0, originator: nil)
            } label: {
              Text("Max")
            }
          }
          Toggle(isOn: synth.binding(to: synth.retrigger.address, with: $retriggerToggle)) {
            Text("Retrigger")
          }
          Toggle(isOn: synth.binding(to: synth.monophonic.address, with: $monophonicToggle)) {
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

#if DEBUG

struct DualityViewPreview: PreviewProvider {
  @MainActor
  static var previews: some View {
    VStack {
      DualityView()
    }
  }
}

#endif // DEBUG
