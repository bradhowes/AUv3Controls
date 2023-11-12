import AVFoundation
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
            return control.reduce(into: &state.control, action: .title(.valueChanged(newValue)))
              .map { Action.control($0) }
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
  let proxy: ScrollViewProxy?

  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ZStack {
        ControlView(store: store.scope(state: \.control, action: { .control($0) }), config: config, proxy: proxy)
          .controlVisible(viewStore.editor.focus)
        EditorView(store: store.scope(state: \.editor, action: { .editor($0) }), config: config)
          .editorVisible(viewStore.editor.focus)
      }
      .frame(maxWidth: config.controlWidthIf(viewStore.editor.focus), maxHeight: config.maxHeight)
      .frame(width: config.controlWidthIf(viewStore.editor.focus), height: config.maxHeight)
      .id(config.parameter.address)
      .animation(.linear, value: viewStore.editor.focus != nil)
    }
  }
}

private extension View {

  func controlVisible(_ field: EditorFeature.State.Field?) -> some View {
    self.opacity(field != nil ? 0.0 : 1.0)
      .scaleEffect(field != nil ? 0.0 : 1.0)
  }

  func editorVisible(_ field: EditorFeature.State.Field?) -> some View {
    self.opacity(field == nil ? 0.0 : 1.0)
      .scaleEffect(field == nil ? 0.0 : 1.0)
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
    KnobView(store: store, config: config, proxy: nil)
  }
}
