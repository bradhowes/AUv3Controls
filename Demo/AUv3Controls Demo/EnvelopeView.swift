// Copyright © 2025 Brad Howes. All rights reserved.

import AUv3Controls
import AVFoundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct EnvelopeFeature {
  let delay: AUParameter
  let attack: AUParameter
  let hold: AUParameter
  let decay: AUParameter
  let sustain: AUParameter
  let release: AUParameter

  init(parameterBase: AUParameterAddress) {
    delay = AUParameterTree.createParameter(
      withIdentifier: "DELAY",
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

    attack = AUParameterTree.createParameter(
      withIdentifier: "ATTACK",
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

    hold = AUParameterTree.createParameter(
      withIdentifier: "HOLD",
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

    decay = AUParameterTree.createParameter(
      withIdentifier: "DECAY",
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

    sustain = AUParameterTree.createParameter(
      withIdentifier: "SUSTAIN",
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

    release = AUParameterTree.createParameter(
      withIdentifier: "RELEASE",
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
  }

  @ObservableState
  struct State: Equatable {
    var enabled: ToggleFeature.State
    var locked: ToggleFeature.State
    var delay: KnobFeature.State
    var attack: KnobFeature.State
    var hold: KnobFeature.State
    var decay: KnobFeature.State
    var sustain: KnobFeature.State
    var release: KnobFeature.State

    init(
      delay: AUParameter,
      attack: AUParameter,
      hold: AUParameter,
      decay: AUParameter,
      sustain: AUParameter,
      release: AUParameter
    ) {
      self.enabled = ToggleFeature.State(isOn: true, displayName: "On")
      self.locked = ToggleFeature.State(isOn: false, displayName: "Lock")
      self.delay = KnobFeature.State(parameter: delay)
      self.attack = KnobFeature.State(parameter: attack)
      self.hold = KnobFeature.State(parameter: hold)
      self.decay = KnobFeature.State(parameter: decay)
      self.sustain = KnobFeature.State(parameter: sustain)
      self.release = KnobFeature.State(parameter: release)
    }
  }

  var state: State {
    .init(delay: delay, attack: attack, hold: hold, decay: decay, sustain: sustain, release: release)
  }

  enum Action {
    case enabled(ToggleFeature.Action)
    case locked(ToggleFeature.Action)
    case delay(KnobFeature.Action)
    case attack(KnobFeature.Action)
    case hold(KnobFeature.Action)
    case decay(KnobFeature.Action)
    case sustain(KnobFeature.Action)
    case release(KnobFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.enabled, action: \.enabled) { ToggleFeature() }
    Scope(state: \.locked, action: \.locked) { ToggleFeature() }
    Scope(state: \.delay, action: \.delay) { KnobFeature(parameter: delay) }
    Scope(state: \.attack, action: \.attack) { KnobFeature(parameter: attack) }
    Scope(state: \.hold, action: \.hold) { KnobFeature(parameter: hold) }
    Scope(state: \.decay, action: \.decay) { KnobFeature(parameter: decay) }
    Scope(state: \.sustain, action: \.sustain) { KnobFeature(parameter: sustain) }
    Scope(state: \.release, action: \.release) { KnobFeature(parameter: release) }

    Reduce { state, action in
      switch action {
      case .enabled: return .none
      case .locked: return .none
      case .delay: return .none
      case .attack: return .none
      case .hold: return .none
      case .decay: return .none
      case .sustain: return .none
      case .release: return .none
      }
    }
  }
}

struct EnvelopeView: View {
  @Bindable private var store: StoreOf<EnvelopeFeature>
  let title: String
  @Environment(\.auv3ControlsTheme) var theme

  init(store: StoreOf<EnvelopeFeature>, title: String) {
    self.store = store
    self.title = title
  }

  var body: some View {
    EffectsContainer(
      enabled: store.enabled.isOn,
      title: title,
      onOff: ToggleView(store: store.scope(state: \.enabled, action: \.enabled)),
      globalLock: ToggleView(store: store.scope(state: \.locked, action: \.locked)) { Image(systemName: "lock") }
    ) {
      HStack(alignment: .center, spacing: 8) {
        KnobView(store: store.scope(state: \.delay, action: \.delay))
        KnobView(store: store.scope(state: \.attack, action: \.attack))
        KnobView(store: store.scope(state: \.hold, action: \.hold))
        KnobView(store: store.scope(state: \.decay, action: \.decay))
        KnobView(store: store.scope(state: \.sustain, action: \.sustain))
        KnobView(store: store.scope(state: \.release, action: \.release))
      }
    }
  }
}

struct EnvelopeViews: View {
  var body: some View {
    var theme = Theme()
    theme.controlTrackStrokeStyle = StrokeStyle(lineWidth: 5, lineCap: .round)
    theme.controlValueStrokeStyle = StrokeStyle(lineWidth: 3, lineCap: .round)
    theme.toggleOnIndicatorSystemName = "arrowtriangle.down.fill"
    theme.toggleOffIndicatorSystemName = "arrowtriangle.down"

    let vol = EnvelopeFeature(parameterBase: 100)
    let mod = EnvelopeFeature(parameterBase: 200)

    return VStack {
      ScrollView(.horizontal) {
        EnvelopeView(store: Store(initialState: vol.state) { vol }, title: "Amp")
          .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
          .border(theme.controlForegroundColor)
      }
      ScrollView(.horizontal) {
        EnvelopeView(store: Store(initialState: mod.state) { mod }, title: "Mod")
          .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
          .environment(\.auv3ControlsTheme, theme)
          .border(theme.controlForegroundColor)
      }
    }
  }
}

struct EnvelopeViewPreview: PreviewProvider {
  static var previews: some View {
    EnvelopeViews()
  }
}
