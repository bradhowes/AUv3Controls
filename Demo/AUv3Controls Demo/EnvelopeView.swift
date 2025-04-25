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

    let config = KnobConfig()
    let delayParam = AUParameterTree.createParameter(withIdentifier: "DELAY", name: "Delay", address: 1, min: 0.0,
                                                     max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                     valueStrings: nil, dependentParameters: nil)
    let delayStore = Store(initialState: KnobFeature.State(
      parameter: delayParam,
      formatter: .duration(1...3),
      config: config
    )) {
      KnobFeature()
    }

    let attackParam = AUParameterTree.createParameter(withIdentifier: "ATTACK", name: "Attack", address: 2, min: 0.0,
                                                      max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                      valueStrings: nil, dependentParameters: nil)
    let attackStore = Store(initialState: KnobFeature.State(
      parameter: attackParam,
      formatter: .duration(1...3),
      config: config
    )) {
      KnobFeature()
    }

    let holdParam = AUParameterTree.createParameter(withIdentifier: "HOLD", name: "Hold", address: 3, min: 0.0,
                                                    max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                    valueStrings: nil, dependentParameters: nil)
    let holdStore = Store(initialState: KnobFeature.State(
      parameter: holdParam,
      formatter: .percentage(1...3),
      config: config
    )) {
      KnobFeature()
    }

    let decayParam = AUParameterTree.createParameter(withIdentifier: "DECAY", name: "Decay", address: 4, min: 0.0,
                                                     max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                     valueStrings: nil, dependentParameters: nil)
    let decayStore = Store(initialState: KnobFeature.State(
      parameter: decayParam,
      formatter: .duration(1...3),
      config: config
    )) {
      KnobFeature()
    }

    let sustainParam = AUParameterTree.createParameter(withIdentifier: "SUSTAIN", name: "Sustain", address: 5, min: 0.0,
                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                       valueStrings: nil, dependentParameters: nil)
    let sustainStore = Store(initialState: KnobFeature.State(
      parameter: sustainParam,
      formatter: .percentage(1...3),
      config: config
    )) {
      KnobFeature()
    }

    let releaseParam = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 6, min: 0.0,
                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                       valueStrings: nil, dependentParameters: nil)
    let releaseStore = Store(initialState: KnobFeature.State(
      parameter: releaseParam,
      formatter: .duration(1...3),
      config: config
    )) {
      KnobFeature()
    }

    ScrollView(.horizontal) {
      ScrollViewReader { proxy in
        GroupBox(label: label) {
          HStack {
            KnobView(store: delayStore)
            KnobView(store: attackStore)
            KnobView(store: holdStore)
            KnobView(store: decayStore)
            KnobView(store: sustainStore)
            KnobView(store: releaseStore)
          }
          .padding(.bottom)
          .scrollViewProxy(proxy)
        }
        .background(Color.black.opacity(0.2))
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
