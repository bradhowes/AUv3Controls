import SwiftUI

extension View {

  /// Fade out the view when the condition is true
  func fadeOut(when condition: Bool) -> some View { self.opacity(condition ? 0.0 : 1.0) }

  /// Fade in the view when the condition is true
  func fadeIn(when condition: Bool) -> some View { self.opacity(condition ? 1.0 : 0.0) }

  /// Shrink down the view to nothing if the condition is true
  func shrinkDown(when condition: Bool) -> some View { self.scaleEffect(condition ? 0.0 : 1.0) }

  /// Expand to normal size when the condition is true
  func expandUp(when condition: Bool) -> some View { self.scaleEffect(condition ? 1.0 : 0.0) }

  /// Fade in and expand to normal size if the condition is true
  func visible(when condition: Bool) -> some View {
    self.expandUp(when: condition)
      .fadeIn(when: condition)
  }
}
