// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

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
