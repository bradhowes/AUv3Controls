// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

extension View {

  /// Fade out the view when the condition is true
  public func fadeOut(when condition: Bool) -> some View { self.opacity(condition ? 0.0 : 1.0) }

  /// Fade in the view when the condition is true
  public func fadeIn(when condition: Bool) -> some View { self.opacity(condition ? 1.0 : 0.0) }

  /// Shrink down the view to nothing if the condition is true
  public func shrinkDown(when condition: Bool) -> some View { self.scaleEffect(condition ? 0.0 : 1.0) }

  /// Expand to normal size when the condition is true
  public func expandUp(when condition: Bool) -> some View { self.scaleEffect(condition ? 1.0 : 0.0) }

  /// Fade in and expand to normal size if the condition is true
  public func visible(when condition: Bool) -> some View {
    self.expandUp(when: condition)
      .fadeIn(when: condition)
  }
}

// From https://www.hackingwithswift.com/quick-start/swiftui/swiftui-tips-and-tricks
//
// Example:
// ```
//   Text("Hello World")
//     .iOS { $0.padding(10) }
// ```

extension View {
  public func iOS<Content: View>(_ modifier: (Self) -> Content) -> some View {
#if os(iOS)
    return modifier(self)
#else
    return self
#endif
  }
}

extension View {
  public func macOS<Content: View>(_ modifier: (Self) -> Content) -> some View {
#if os(macOS)
    return modifier(self)
#else
    return self
#endif
  }
}

extension View {
  public func tvOS<Content: View>(_ modifier: (Self) -> Content) -> some View {
#if os(tvOS)
    return modifier(self)
#else
    return self
#endif
  }
}

extension View {
  public func watchOS<Content: View>(_ modifier: (Self) -> Content) -> some View {
#if os(watchOS)
    return modifier(self)
#else
    return self
#endif
  }
}

extension EnvironmentValues {
  @Entry public var scrollViewProxy: ScrollViewProxy?
  @Entry public var auv3ControlsTheme: Theme = Theme()
  @Entry public var auv3ControlsKnobConfig: KnobConfig = KnobConfig()
}

extension View {
  public func scrollViewProxy(_ value: ScrollViewProxy?) -> some View { environment(\.scrollViewProxy, value) }
  public func auv3ControlsKnobConfig(_ value: KnobConfig) -> some View { environment(\.auv3ControlsKnobConfig, value) }
  public func auv3ControlsTheme(_ value: Theme) -> some View { environment(\.auv3ControlsTheme, value) }
}
