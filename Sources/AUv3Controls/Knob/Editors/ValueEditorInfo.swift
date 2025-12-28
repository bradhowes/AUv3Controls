import Sharing

/**
 Shared state that defines the KnobFeature value that is currently being edited. This is stored in an in-memory
 shared key `Shared(.valueEditorInfo)`. When a KnobFeature wants to present a value editor, it should set this
 shared key to a `ValueEditorInfo` instance that identifies the KnobFeature and the current value it holds. When
 the editing is done, the editor will set the `action` state to `.dismissed` along with the new value to use if
 the change was accepted by the user. The KnobFeature is then responsible for updating its state with the new
 value (if any) and for setting the `Shared(.valueEditorInfo)` value to nil.
 */
struct ValueEditorInfo: Equatable, Sendable {

  /**
   The state of the editor view:

   * presented -- the editor view is presented to the user
   * dismissed(String?) -- the editor view was dismissed by the user. If associated value is not nil then user
   accepted the new value.
   */
  enum Action: Equatable {
    case presented
    case dismissed(String?)
  }

  /// The ID of the value being edited
  let id: UInt64
  /// The display name of the value being edited
  let displayName: String
  /// The current formatted value
  let value: String
  /// The current action for the editor
  var action: Action = .presented
  /// The theme to use for the editor view
  var theme: Theme
}

extension SharedKey where Self == InMemoryKey<ValueEditorInfo?>.Default {
  static var valueEditorInfo: Self {
    Self[.inMemory("valueEditorInfo"), default: nil]
  }
}
