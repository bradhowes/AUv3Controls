// Copyright © 2025 Brad Howes. All rights reserved.

import AVFoundation
import ComposableArchitecture
import SwiftUI

struct EnvelopeView: View {
  let title: String
  @Environment(\.auv3ControlsTheme) var theme

  var body: some View {
    let label = Text(title)
      .foregroundStyle(theme.controlForegroundColor)
      .font(.caption.smallCaps())

    let config = KnobConfig()

    let enableStore = Store(initialState: ToggleFeature.State(isOn: true, displayName: "On")) { ToggleFeature() }
    let lockStore = Store(initialState: ToggleFeature.State(isOn: true, displayName: "Lock")) { ToggleFeature() }

    let delayParam = AUParameterTree.createParameter(withIdentifier: "DELAY", name: "Delay", address: 1, min: 0.0,
                                                     max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                     valueStrings: nil, dependentParameters: nil)
    let delayStore = Store(initialState: KnobFeature.State(
      parameter: delayParam,
      formatter: .duration(1...1),
      config: config
    )) {
      KnobFeature()
    }

    let attackParam = AUParameterTree.createParameter(withIdentifier: "ATTACK", name: "Attack", address: 2, min: 0.0,
                                                      max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                      valueStrings: nil, dependentParameters: nil)
    let attackStore = Store(initialState: KnobFeature.State(
      parameter: attackParam,
      formatter: .duration(1...2),
      config: config
    )) {
      KnobFeature()
    }

    let holdParam = AUParameterTree.createParameter(withIdentifier: "HOLD", name: "Hold", address: 3, min: 0.0,
                                                    max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                    valueStrings: nil, dependentParameters: nil)
    let holdStore = Store(initialState: KnobFeature.State(
      parameter: holdParam,
      formatter: .general(1...3),
      config: config
    )) {
      KnobFeature()
    }

    let decayParam = AUParameterTree.createParameter(withIdentifier: "DECAY", name: "Decay", address: 4, min: 0.0,
                                                     max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                     valueStrings: nil, dependentParameters: nil)
    let decayStore = Store(initialState: KnobFeature.State(
      parameter: decayParam,
      formatter: .duration(1...4),
      config: config
    )) {
      KnobFeature()
    }

    let sustainParam = AUParameterTree.createParameter(withIdentifier: "SUSTAIN", name: "Sustain", address: 5, min: 0.0,
                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                       valueStrings: nil, dependentParameters: nil)
    let sustainStore = Store(initialState: KnobFeature.State(
      parameter: sustainParam,
      formatter: .general(2...4),
      config: config
    )) {
      KnobFeature()
    }

    let releaseParam = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 6, min: 0.0,
                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                       valueStrings: nil, dependentParameters: nil)
    let releaseStore = Store(initialState: KnobFeature.State(
      parameter: releaseParam,
      formatter: .duration(1...4),
      config: config
    )) {
      KnobFeature()
    }

    ScrollViewReader { proxy in
      ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 12) {
          VStack(alignment: .leading, spacing: 18) {
            label
            ToggleView(store: enableStore) { Text(enableStore.displayName) }
            ToggleView(store: lockStore) { Image(systemName: "lock") }
          }
          KnobView(store: delayStore)
          KnobView(store: attackStore)
          KnobView(store: holdStore)
          KnobView(store: decayStore)
          KnobView(store: sustainStore)
          KnobView(store: releaseStore)
        }
        .frame(height: 100)
        .padding()
        .border(theme.controlBackgroundColor, width: 1)
      }.scrollViewProxy(proxy)
    }
  }
}

struct EnvelopeViewPreview: PreviewProvider {
  static var previews: some View {
    var volumeTheme = Theme()
    volumeTheme.controlTrackStrokeStyle = StrokeStyle(lineWidth: 5, lineCap: .round)
    volumeTheme.controlValueStrokeStyle = StrokeStyle(lineWidth: 3, lineCap: .round)
    volumeTheme.toggleOnIndicatorSystemName = "arrowtriangle.down.fill"
    volumeTheme.toggleOffIndicatorSystemName = "arrowtriangle.down"
    // let modTheme = Theme()
    return VStack {
      EnvelopeView(title: "Volume")
        .environment(\.auv3ControlsTheme, volumeTheme)
      EnvelopeView(title: "Mod")
        .environment(\.auv3ControlsTheme, volumeTheme)
    }
  }
}
