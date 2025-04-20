import AVFoundation
import ComposableArchitecture
import SwiftUI

struct EnvelopeView: View {
  let title: String
  let theme = Theme()

  var body: some View {
    let label = Text(title)
      .foregroundStyle(theme.controlForegroundColor)
      .font(.title2.smallCaps())

    let delayParam = AUParameterTree.createParameter(withIdentifier: "DELAY", name: "Delay", address: 1, min: 0.0,
                                                     max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                     valueStrings: nil, dependentParameters: nil)
    let delayConfig = KnobConfig(parameter: delayParam)
    let delayStore = Store(initialState: KnobFeature.State(config: delayConfig)) {
      KnobFeature()
    }

    let attackParam = AUParameterTree.createParameter(withIdentifier: "ATTACK", name: "Attack", address: 2, min: 0.0,
                                                      max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                      valueStrings: nil, dependentParameters: nil)
    let attackConfig = KnobConfig(parameter: attackParam)
    let attackStore = Store(initialState: KnobFeature.State(config: attackConfig)) {
      KnobFeature()
    }

    let holdParam = AUParameterTree.createParameter(withIdentifier: "HOLD", name: "Hold", address: 3, min: 0.0,
                                                    max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                    valueStrings: nil, dependentParameters: nil)
    let holdConfig = KnobConfig(parameter: holdParam)
    let holdStore = Store(initialState: KnobFeature.State(config: holdConfig)) {
      KnobFeature()
    }

    let decayParam = AUParameterTree.createParameter(withIdentifier: "DECAY", name: "Decay", address: 4, min: 0.0,
                                                     max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                     valueStrings: nil, dependentParameters: nil)
    let decayConfig = KnobConfig(parameter: decayParam)
    let decayStore = Store(initialState: KnobFeature.State(config: decayConfig)) {
      KnobFeature()
    }

    let sustainParam = AUParameterTree.createParameter(withIdentifier: "SUSTAIN", name: "Sustain", address: 5, min: 0.0,
                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                       valueStrings: nil, dependentParameters: nil)
    let sustainConfig = KnobConfig(parameter: sustainParam)
    let sustainStore = Store(initialState: KnobFeature.State(config: sustainConfig)) {
      KnobFeature()
    }

    let releaseParam = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 6, min: 0.0,
                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                       valueStrings: nil, dependentParameters: nil)
    let releaseConfig = KnobConfig(parameter: releaseParam)
    let releaseStore = Store(initialState: KnobFeature.State(config: releaseConfig)) {
      KnobFeature()
    }

    ScrollViewReader { proxy in
      ScrollView(.horizontal) {
        GroupBox(label: label) {
          HStack(spacing: 12) {
            KnobView(store: delayStore)
            KnobView(store: attackStore)
            KnobView(store: holdStore)
            KnobView(store: decayStore)
            KnobView(store: sustainStore)
            KnobView(store: releaseStore)
          }
          .padding(.bottom)
        }
        .border(theme.controlBackgroundColor, width: 1)
      }.scrollViewProxy(proxy)
    }
  }
}

struct EnvelopeViewPreview: PreviewProvider {
  static var previews: some View {
    VStack {
      EnvelopeView(title: "Volume")
      EnvelopeView(title: "Modulation")
    }
  }
}
