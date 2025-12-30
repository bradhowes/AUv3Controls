import Sharing
import SwiftUI

/**
 Shared state that defines the KnobFeature value that is currently being edited. This is stored in an in-memory
 shared key `Shared(.valueEditorInfo)`. When a KnobFeature wants to present a value editor, it should set this
 shared key to a `ValueEditorInfo` instance that identifies the KnobFeature and the current value it holds. When
 the editing is done, the editor will set the `action` state to `.dismissed` along with the new value to use if
 the change was accepted by the user. The KnobFeature is then responsible for updating its state with the new
 value (if any) and for setting the `Shared(.valueEditorInfo)` value to nil.
 */
public struct ValueEditorInfo: Equatable, Sendable {

  /// Flag indicating that decimal point can be entered
  public enum DecimalFlag: Equatable, Sendable {
    case allowed
    case none
  }

  /// Flag indicating that a sign can be entered at start of value
  public enum SignFlag: Equatable, Sendable {
    case allowed
    case none
  }

  /**
   The actions of the editor view:

   * presented -- the editor view is presented to the user
   * dismissed(String?) -- the editor view was dismissed by the user. If associated value is not nil then user
   accepted a new value.
   */
  public enum Action: Equatable, Sendable {
    case presented
    case dismissed(String?)
  }

  /// The ID of the value being edited
  public let id: UInt64
  /// The display name of the value being edited
  public let displayName: String
  /// The current formatted value
  public let value: String
  /// The current action for the editor
  public var action: Action = .presented
  /// The theme to use for the editor view
  public let theme: Theme
  /// Flag indicating if decimal separator is allowed
  public let decimalAllowed: DecimalFlag
  /// Flag indicating if value can start with a sign indicator (+ or -)
  public let signAllowed: SignFlag

  private let decimalSeparator: String
  private let validCharacters: String

  /**
   Construct new instance that indicats the value to edit and what values can be entered in the editor.

   - parameter id the unique identifier of the value being edited
   - parameter displayName the name of the value being edited
   - parameter value the current value of the parameter as text
   - parameter theme the theme being used for a parameter value
   - parameter decimalAllowed flag indicating if a decimal value can be entered
   - parameter signAllowed flag indicating if a "+" or "-" character can be entered as the first character of the value
   */
  public init(id: UInt64, displayName: String, value: String, theme: Theme, decimalAllowed: DecimalFlag, signAllowed: SignFlag) {
    self.id = id
    self.displayName = displayName
    self.value = value
    self.theme = theme
    self.decimalAllowed = decimalAllowed
    self.signAllowed = signAllowed
    self.decimalSeparator = decimalAllowed == .allowed ? (Locale.current.decimalSeparator ?? ".") : ""
    self.validCharacters = "0123456789" + decimalSeparator
  }

  public func isValid(_ text: String) -> Bool {
    var text = text
    if signAllowed == .allowed {
      // Only allowed as first character
      if text.first == "-" || text.first == "+" {
        text = String(text.dropFirst())
      }
    }
    if decimalAllowed == .allowed && !decimalSeparator.isEmpty {
      // One decimalSeparator will lead to two components.
      if text.components(separatedBy: decimalSeparator).count > 2 {
        return false
      }
    }
    return text.allSatisfy { validCharacters.contains($0) }
  }
}

extension SharedKey where Self == InMemoryKey<ValueEditorInfo?>.Default {
  static var valueEditorInfo: Self {
    Self[.inMemory("valueEditorInfo"), default: nil]
  }
}

public enum ValueEditorKind {
  case nativePrompt
#if os(iOS)
  case customPrompt
#endif

#if os(iOS)
  public static var defaultValue: Self {
    return .customPrompt
  }
#else
  public static var defaultValue: Self {
    return .nativePrompt
  }
#endif
}
