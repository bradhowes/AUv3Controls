import AVFoundation
import ComposableArchitecture
import SwiftUI

public struct KnobFeature: Reducer {
  public let config: KnobConfig

  private let control: ControlFeature
  private let editor: EditorFeature

  public init(config: KnobConfig) {
    self.config = config
    self.control = .init(config: config)
    self.editor = .init(config: config)
  }

  public struct State: Equatable, Identifiable {
    public let id: ID

    var control: ControlFeature.State
    var editor: EditorFeature.State
    var observerToken: AUParameterObserverToken?

    public init(config: KnobConfig) {
      self.id = config.id
      self.control = .init(config: config)
      self.editor = .init()
    }
  }

  public enum Action: Equatable, Sendable {
    case control(ControlFeature.Action)
    case editor(EditorFeature.Action)
    case observationStart
    case observationStopped
    case observedValueChanged(AUValue)
  }

  public var body: some Reducer<State, Action> {
    Scope(state: \.control, action: /Action.control) {
      control
    }
    Scope(state: \.editor, action: /Action.editor) {
      editor
    }
    Reduce { state, action in

      func updateParameter(_ value: Double) {
        if let token = state.observerToken {
          Logger.shared.log("setting \(config.title) to \(value)")
          config.parameter.setValue(AUValue(value), originator: token)
        }
      }

      switch action {

      case let .control(controlAction):

        switch controlAction {

        case .track:
          let value = config.normToValue(state.control.track.norm)
          updateParameter(value)
          return .none

        case let .title(titleAction):

          switch titleAction {

          case .tapped:
            let value = config.normToValue(state.control.track.norm)
            Logger.shared.log("showing \(config.title) editor")
            return editor.start(state: &state.editor, value: value)
              .map(Action.editor)

          default:
            return .none
          }
        }

      case let .editor(editorAction):

        switch editorAction {

        case .acceptButtonTapped:
          if let value = Double(state.editor.value) {
            updateParameter(value)
            return control.updateAndShowValue(state: &state.control, value: value)
              .map(Action.control)
          }
          return .none

        default:
          return .none
        }

      case .observationStart:
        let title = config.title
        Logger.shared.log("\(title) - started observing values")

        let stream: AsyncStream<AUValue>
        (state.observerToken, stream) = config.parameter.startObserving()

        return .run { send in
          for await value in stream {
            await send(.observedValueChanged(value))
          }
          Logger.shared.log("\(title) - observation async stream stopped")
          await send(.observationStopped)
        }.cancellable(id: state.id, cancelInFlight: true)

      case .observationStopped:
        Logger.shared.log("\(config.title) - stopped observing values")
        if let token = state.observerToken {
          config.parameter.removeParameterObserver(token)
          state.observerToken = nil
        }
        return .cancel(id: state.id)

      case let .observedValueChanged(value):
        return control.updateAndShowValue(state: &state.control, value: Double(value))
          .map(Action.control)
      }
    }
  }
}

public struct KnobView: View {
  let store: StoreOf<KnobFeature>
  let config: KnobConfig
  let proxy: ScrollViewProxy?

  public init(store: StoreOf<KnobFeature>, config: KnobConfig, proxy: ScrollViewProxy? = nil) {
    self.store = store
    self.config = config
    self.proxy = proxy
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ZStack {
        ControlView(store: store.scope(state: \.control, action: { .control($0) }), config: config, proxy: proxy)
          .visible(when: !viewStore.editor.hasFocus)
        EditorView(store: store.scope(state: \.editor, action: { .editor($0) }), config: config)
          .visible(when: viewStore.editor.hasFocus)
      }
      .animation(.linear, value: viewStore.editor.hasFocus)
      .frame(maxWidth: config.controlWidthIf(viewStore.editor.focus), maxHeight: config.maxHeight)
      .frame(width: config.controlWidthIf(viewStore.editor.focus), height: config.maxHeight)
      .id(viewStore.id)
      .task { await viewStore.send(.observationStart).finish() }
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
    KnobView(store: store, config: config, proxy: nil)
  }
}
