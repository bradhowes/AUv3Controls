import ComposableArchitecture
import Sharing
import SwiftUI

/**
 Presents a native SwiftUI alert with a TextField to edit the value of a KnobFeature.
 */
struct NativeValueEditorHost: ViewModifier {
  @Shared(.valueEditorInfo) var valueEditorInfo
  @State private var displayName: String = ""
  @State private var value: String = ""
  @State private var isEditing: Bool = false

  func body(content: Content) -> some View {
    content
      .onChange(of: valueEditorInfo) {
        if let valueEditorInfo {
          displayName = valueEditorInfo.displayName
          value = valueEditorInfo.value
          isEditing = true
        } else {
          isEditing = false
        }
      }
      .alert(displayName, isPresented: $isEditing) {
        TextField("New Value", text: $value)
#if os(iOS)
          .keyboardType(.decimalPad)
#endif
          .onSubmit { dismiss(accepted: true) }
        Button {
          dismiss(accepted: true)
        } label: {
          Text("OK")
        }
        Button(role: .cancel) {
          dismiss(accepted: false)
        } label: {
          Text("Cancel")
        }
      }
  }

  private func dismiss(accepted: Bool) {
    if var valueEditorInfo {
      // Communicate the change to the knob -- the knob is responsible for setting the shared value to nil.
      valueEditorInfo.action = .dismissed(accepted ? value : nil)
      $valueEditorInfo.withLock { $0 = valueEditorInfo }
    }
  }
}

extension View {
  public func knobNativeValueEditorHost() -> some View {
    modifier(NativeValueEditorHost())
  }
}
