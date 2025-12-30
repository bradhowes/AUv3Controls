// Copyright © 2025 Brad Howes. All rights reserved.

import AVFoundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct EnvelopeFeature {

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
    Scope(state: \.delay, action: \.delay) { KnobFeature() }
    Scope(state: \.attack, action: \.attack) { KnobFeature() }
    Scope(state: \.hold, action: \.hold) { KnobFeature() }
    Scope(state: \.decay, action: \.decay) { KnobFeature() }
    Scope(state: \.sustain, action: \.sustain) { KnobFeature() }
    Scope(state: \.release, action: \.release) { KnobFeature() }

    Reduce { _, action in
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
  private let title: String
  @Bindable private var store: StoreOf<EnvelopeFeature>

  init(title: String, store: StoreOf<EnvelopeFeature>) {
    self.title = title
    self.store = store
  }

  var body: some View {
    NamedKnobCollectionContainer(
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

struct AmpEnvelopeView: View {
  @Environment(\.auv3ControlsTheme) private var theme
  let mockAUv3: MockAUv3

  var body: some View {
    ScrollView(.horizontal) {
      EnvelopeView(
        title: "Amp",
        store: Store(
          initialState: EnvelopeFeature.State(
            delay: mockAUv3.ampDelay,
            attack: mockAUv3.ampAttack,
            hold: mockAUv3.ampHold,
            decay: mockAUv3.ampDecay,
            sustain: mockAUv3.ampSustain,
            release: mockAUv3.ampRelease
          )
        ) {
          EnvelopeFeature()
        }
      )
      .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
      .border(theme.controlForegroundColor)
    }
  }
}

struct ModEnvelopeView: View {
  @Environment(\.auv3ControlsTheme) private var theme
  let mockAUv3: MockAUv3

  var body: some View {
    ScrollView(.horizontal) {
      EnvelopeView(
        title: "Mod",
        store: Store(
          initialState: EnvelopeFeature.State(
            delay: mockAUv3.modDelay,
            attack: mockAUv3.modAttack,
            hold: mockAUv3.modHold,
            decay: mockAUv3.modDecay,
            sustain: mockAUv3.modSustain,
            release: mockAUv3.modRelease
          )
        ) {
          EnvelopeFeature()
        }
      )
      .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
      .border(theme.controlForegroundColor)
    }
  }
}

public struct EnvelopeViews: View {
  private let mockAUv3: MockAUv3
  @Environment(\.colorScheme) private var colorScheme

  private func theme(title: String) -> Theme {
    var theme = Theme(colorScheme: colorScheme)
    theme.controlTrackStrokeStyle = StrokeStyle(lineWidth: 5, lineCap: .round)
    theme.controlValueStrokeStyle = StrokeStyle(lineWidth: 3, lineCap: .round)

    if title == "Mod" {
      theme.controlForegroundColor = theme.taggedColor(.controlForegroundColor, default: .red)
      let defaultTextColor = Color.red.mix(with: Color.black, by: 0.15)
      theme.textColor = theme.taggedColor(.textColor, default: defaultTextColor)
      theme.editorCancelButtonColor = theme.taggedColor(.editorCancelButtonColor, default: defaultTextColor)
      theme.editorOKButtonColor = theme.taggedColor(.editorOKButtonColor, default: defaultTextColor)
      theme.toggleOnIndicatorSystemName = "arrowtriangle.down.fill"
      theme.toggleOffIndicatorSystemName = "arrowtriangle.down"
    }

    return theme
  }

  public init() {
    let mockAUv3 = MockAUv3()
    self.mockAUv3 = mockAUv3
  }

  public var body: some View {
    VStack {
      AmpEnvelopeView(mockAUv3: mockAUv3)
        .auv3ControlsTheme(theme(title: "Amp"))
      ModEnvelopeView(mockAUv3: mockAUv3)
        .auv3ControlsTheme(theme(title: "Mod"))
    }
    .knobValueEditor()
  }
}

struct EnvelopeViewPreview: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      EnvelopeViews()
    }
  }
}
