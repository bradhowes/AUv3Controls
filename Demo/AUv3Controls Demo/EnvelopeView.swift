import AVFoundation
import ComposableArchitecture
import SwiftUI
import AUv3Controls

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
    let delayConfig = KnobConfig(parameter: delayParam, theme: theme)
    let delayStore = Store(initialState: KnobFeature.State(config: delayConfig)) {
      KnobFeature(config: delayConfig)
    }

    let attackParam = AUParameterTree.createParameter(withIdentifier: "ATTACK", name: "Attack", address: 2, min: 0.0,
                                                      max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                      valueStrings: nil, dependentParameters: nil)
    let attackConfig = KnobConfig(parameter: attackParam, theme: theme)
    let attackStore = Store(initialState: KnobFeature.State(config: attackConfig)) {
      KnobFeature(config: attackConfig)
    }

    let holdParam = AUParameterTree.createParameter(withIdentifier: "HOLD", name: "Hold", address: 3, min: 0.0,
                                                    max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                    valueStrings: nil, dependentParameters: nil)
    let holdConfig = KnobConfig(parameter: holdParam, theme: theme)
    let holdStore = Store(initialState: KnobFeature.State(config: attackConfig)) {
      KnobFeature(config: holdConfig)
    }

    let decayParam = AUParameterTree.createParameter(withIdentifier: "DECAY", name: "Decay", address: 4, min: 0.0,
                                                     max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                     valueStrings: nil, dependentParameters: nil)
    let decayConfig = KnobConfig(parameter: decayParam, theme: theme)
    let decayStore = Store(initialState: KnobFeature.State(config: decayConfig)) {
      KnobFeature(config: decayConfig)
    }

    let sustainParam = AUParameterTree.createParameter(withIdentifier: "SUSTAIN", name: "Sustain", address: 5, min: 0.0,
                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                       valueStrings: nil, dependentParameters: nil)
    let sustainConfig = KnobConfig(parameter: sustainParam, theme: theme)
    let sustainStore = Store(initialState: KnobFeature.State(config: sustainConfig)) {
      KnobFeature(config: sustainConfig)
    }

    let releaseParam = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 6, min: 0.0,
                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                       valueStrings: nil, dependentParameters: nil)
    let releaseConfig = KnobConfig(parameter: releaseParam, theme: theme)
    let releaseStore = Store(initialState: KnobFeature.State(config: releaseConfig)) {
      KnobFeature(config: releaseConfig)
    }

    ScrollViewReader { proxy in
      ScrollView(.horizontal) {
        GroupBox(label: label) {
          HStack(spacing: 12) {
            KnobView(store: delayStore, config: delayConfig, proxy: proxy)
            KnobView(store: attackStore, config: attackConfig, proxy: proxy)
            KnobView(store: holdStore, config: holdConfig, proxy: proxy)
            KnobView(store: decayStore, config: decayConfig, proxy: proxy)
            KnobView(store: sustainStore, config: sustainConfig, proxy: proxy)
            KnobView(store: releaseStore, config: releaseConfig, proxy: proxy)
          }
          .padding(.bottom)
        }
        .border(theme.controlBackgroundColor, width: 1)
      }
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
