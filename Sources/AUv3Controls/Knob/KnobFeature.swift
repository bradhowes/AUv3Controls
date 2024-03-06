import AVFoundation
import ComposableArchitecture
import SwiftUI

@Reducer
public struct KnobFeature {
  let config: KnobConfig

  public init(config: KnobConfig) {
    self.config = config
  }

  @ObservableState
  public struct State: Equatable, Identifiable {
    public let id: ID

    var control: ControlFeature.State
    var editor: EditorFeature.State
    var observerToken: AUParameterObserverToken?

    public init(config: KnobConfig) {
      self.id = config.id
      self.control = .init(config: config, value: Double(config.parameter.value))
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
    Scope(state: \.control, action: /Action.control) { ControlFeature(config: config) }
    Scope(state: \.editor, action: /Action.editor) { EditorFeature(config: config) }

    Reduce { state, action in

      func updateParameter(_ value: Double) {
        if let token = state.observerToken {
          config.parameter.setValue(AUValue(value), originator: token)
        }
      }

      switch action {

      case let .control(controlAction):
        switch controlAction {
        case let .track(trackAction):
          if case let .dragChanged = trackAction {
            let value = config.normToValue(state.control.track.norm)
            updateParameter(value)
          }
          return .none

        case let .title(titleAction) where titleAction == .tapped:
          let value = config.normToValue(state.control.track.norm)
          return .send(.editor(.start(value)))

        default:
          return .none
        }

      case let .editor(editorAction) where editorAction == .acceptButtonTapped:
        guard let editorValue = Double(state.editor.value) else { return .none }
        let value = config.normToValue(config.valueToNorm(editorValue))
        updateParameter(value)
        return .send(.control(.valueChanged(value)))

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
        return .send(.control(.valueChanged(Double(value))))

      default:
        return .none
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
    ZStack {
      ControlView(store: store.scope(state: \.control, action: \.control), config: config, proxy: proxy)
        .visible(when: !store.editor.hasFocus)
      EditorView(store: store.scope(state: \.editor, action: \.editor), config: config)
        .visible(when: store.editor.hasFocus)
    }
    .frame(maxWidth: config.controlWidthIf(store.editor.focus), maxHeight: config.maxHeight)
    .frame(width: config.controlWidthIf(store.editor.focus), height: config.maxHeight)
    .task { await store.send(.observationStart).finish() }
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
