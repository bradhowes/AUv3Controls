// Copyright © 2025 Brad Howes. All rights reserved.

import AVFoundation
import SwiftUI

/**
 Global settings for all `KnobFeature` instances.
 */
public struct KnobConfig: Equatable, Sendable {
  public static let `default` = KnobConfig()

  /// How long to show the value in the knob's label
  public let showValueMilliseconds: Int

  /**
   Amount of time to wait with no more AUParameter changes before emitting the last one in the async stream of
   values. Reduces traffic at the expense of increased latency. Note that this is *not* the same as throttling where
   one limits the rate of emission but ultimately emits all events: debouncing drops all but the last event in a
   window of time.
   */
  public let debounceMilliseconds: Int

  public init(
    showValueDuration: Int = 1250,
    debounceDuration: Int = 10
  ) {
    self.showValueMilliseconds = showValueDuration
    self.debounceMilliseconds = debounceDuration
  }
}
