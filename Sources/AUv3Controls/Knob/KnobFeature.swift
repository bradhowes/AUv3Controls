import AVFoundation
import Clocks
import ComposableArchitecture
import SwiftUI


struct KnobFeature: Reducer {
  let config: KnobConfig
  let control: ControlFeature
  let editor: EditorFeature
  
  init(config: KnobConfig) {
    self.config = config
    self.control = .init(config: config)
    self.editor = .init(config: config)
  }
  
  struct State: Equatable {
    var control: ControlFeature.State
    var editor: EditorFeature.State
    
    init(config: KnobConfig) {
      self.control = .init(config: config)
      self.editor = .init()
    }
  }

  enum Action: Equatable, Sendable {
    case control(ControlFeature.Action)
    case editor(EditorFeature.Action)
  }
  
  var body: some Reducer<State, Action> {
    Scope(state: \.control, action: /Action.control) {
      control
    }
    Scope(state: \.editor, action: /Action.editor) {
      editor
    }
    Reduce { state, action in
      switch action {
      case let .control(controlAction):
        switch controlAction {
        case let .title(titleAction):
          switch titleAction {
          case .tapped:
            return editor.reduce(into: &state.editor, action: .editing(config.normToValue(state.control.track.norm)))
              .map { Action.editor($0) }
          default:
            return .none
          }
        default:
          return .none
        }
      case let .editor(editorAction):
        switch editorAction {
        case .acceptButtonTapped:
          if let newValue = Double(state.editor.value) {
            state.control.track.norm = config.valueToNorm(newValue)
          }
          return .none
        default:
          return .none
        }
      }
    }
  }
}

struct KnobView: View {
  let store: StoreOf<KnobFeature>
  let config: KnobConfig
  let scrollViewProxy: ScrollViewProxy?

  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ZStack {
        ControlView(store: store.scope(state: \.control, action: { .control($0) }), config: config)
          .opacity(viewStore.editor.focus != nil ? 0.0 : 1.0)
          .scaleEffect(viewStore.editor.focus != nil ? 0.0 : 1.0)
        EditorView(store: store.scope(state: \.editor, action: { .editor($0) }), config: config)
          .opacity(viewStore.editor.focus == nil ? 0.0 : 1.0)
          .scaleEffect(viewStore.editor.focus == nil ? 0.0 : 1.0)
      }
      .frame(maxWidth: config.controlWidthIf(viewStore.editor.focus), maxHeight: config.maxHeight)
      .frame(width: config.controlWidthIf(viewStore.editor.focus), height: config.maxHeight)
      .id(config.parameter.address)
      .animation(.linear, value: viewStore.editor.focus != nil)
      // .task { await viewStore.send(.viewAppeared).finish() }
    }
  }
}

struct KnobViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  static let config = KnobConfig(parameter: param, logScale: false, theme: Theme())
  @State static var store = Store(initialState: KnobFeature.State(config: config)) {
    KnobFeature(config: config)
  }
    
  static var previews: some View {
    KnobView(store: store, config: config, scrollViewProxy: nil)
  }
}

////struct EnvelopeView: View {
////  let title: String
////  let theme = Theme()
////
////  var body: some View {
////    let label = Text(title)
////      .foregroundStyle(theme.controlForegroundColor)
////      .font(.title2.smallCaps())
////
////    let delayParam = AUParameterTree.createParameter(withIdentifier: "DELAY", name: "Delay", address: 1, min: 0.0,
////                                                     max: 100.0, unit: .generic, unitName: nil, flags: [],
////                                                     valueStrings: nil, dependentParameters: nil)
////    let delayConfig = KnobConfig(parameter: delayParam, theme: theme)
////    let delayStore = Store(initialState: KnobReducer.State(parameter: delayParam, value: 0.0)) {
////      KnobReducer(config: delayConfig)
////    }
////
////    let attackParam = AUParameterTree.createParameter(withIdentifier: "ATTACK", name: "Attack", address: 2, min: 0.0,
////                                                      max: 100.0, unit: .generic, unitName: nil, flags: [],
////                                                      valueStrings: nil, dependentParameters: nil)
////    let attackConfig = KnobConfig(parameter: attackParam, theme: theme)
////    let attackStore = Store(initialState: KnobReducer.State(parameter: attackParam, value: 0.0)) {
////      KnobReducer(config: attackConfig)
////    }
////
////    let holdParam = AUParameterTree.createParameter(withIdentifier: "HOLD", name: "Hold", address: 3, min: 0.0,
////                                                    max: 100.0, unit: .generic, unitName: nil, flags: [],
////                                                    valueStrings: nil, dependentParameters: nil)
////    let holdConfig = KnobConfig(parameter: holdParam, theme: theme)
////    let holdStore = Store(initialState: KnobReducer.State(parameter: holdParam, value: 0.0)) {
////      KnobReducer(config: holdConfig)
////    }
////
////    let decayParam = AUParameterTree.createParameter(withIdentifier: "DECAY", name: "Decay", address: 4, min: 0.0,
////                                                     max: 100.0, unit: .generic, unitName: nil, flags: [],
////                                                     valueStrings: nil, dependentParameters: nil)
////    let decayConfig = KnobConfig(parameter: decayParam, theme: theme)
////    let decayStore = Store(initialState: KnobReducer.State(parameter: decayParam, value: 0.0)) {
////      KnobReducer(config: decayConfig)
////    }
////
////    let sustainParam = AUParameterTree.createParameter(withIdentifier: "SUSTAIN", name: "Sustain", address: 5, min: 0.0,
////                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
////                                                       valueStrings: nil, dependentParameters: nil)
////    let sustainConfig = KnobConfig(parameter: sustainParam, theme: theme)
////    let sustainStore = Store(initialState: KnobReducer.State(parameter: sustainParam, value: 0.0)) {
////      KnobReducer(config: sustainConfig)
////    }
////
////    let releaseParam = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 6, min: 0.0,
////                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
////                                                       valueStrings: nil, dependentParameters: nil)
////    let releaseConfig = KnobConfig(parameter: releaseParam, theme: theme)
////    let releaseStore = Store(initialState: KnobReducer.State(parameter: releaseParam, value: 0.0)) {
////      KnobReducer(config: releaseConfig)
////    }
////
////    ScrollViewReader { proxy in
////      ScrollView(.horizontal) {
////        GroupBox(label: label) {
////          HStack(spacing: 12) {
////            KnobView(store: delayStore, config: delayConfig, scrollViewProxy: proxy)
////            KnobView(store: attackStore, config: attackConfig, scrollViewProxy: proxy)
////            KnobView(store: holdStore, config: holdConfig, scrollViewProxy: proxy)
////            KnobView(store: decayStore, config: decayConfig, scrollViewProxy: proxy)
////            KnobView(store: sustainStore, config: sustainConfig, scrollViewProxy: proxy)
////            KnobView(store: releaseStore, config: releaseConfig, scrollViewProxy: proxy)
////          }
////          .padding(.bottom)
////        }
////        .border(theme.controlBackgroundColor, width: 1)
////      }
////    }
////  }
////}
//
//struct KnobViewPreview: PreviewProvider {
//  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
//                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
//                                                     valueStrings: nil, dependentParameters: nil)
//  static let config = KnobConfig(parameter: param, logScale: false, theme: Theme())
//  @State static var store = Store(initialState: KnobReducer.State(parameter: param, value: 0.0)) {
//    KnobReducer(config: config)
//  }
//
//  static var previews: some View {
//    KnobView(store: store, config: config, scrollViewProxy: nil)
//  }
//}
//
////struct EnvelopeViewPreview: PreviewProvider {
////  static var previews: some View {
////    VStack {
////      EnvelopeView(title: "Volume")
////      EnvelopeView(title: "Modulation")
////    }
////  }
////}
