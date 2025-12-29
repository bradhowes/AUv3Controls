// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

/**
 Custom view that shows a title, an on/off toggle and a "lock" toggle in a vertical row.
 This is used by the
 */
public struct NamedKnobCollectionTitleOnOff<T1: View, T2: View>: View {
  @Environment(\.auv3ControlsTheme) var theme

  let title: String
  let onOffToggleView: T1
  let globalLockToggleView: T2

  public init(title: String, onOffToggleView: T1, globalLockToggleView: T2) {
    self.title = title
    self.onOffToggleView = onOffToggleView
    self.globalLockToggleView = globalLockToggleView
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(title)
        .foregroundStyle(theme.controlForegroundColor)
      onOffToggleView
      globalLockToggleView
    }
  }
}

@available(*, deprecated, renamed: "NamedKnobCollectionTitleOnOff")
public typealias TitleOnOff = NamedKnobCollectionTitleOnOff
