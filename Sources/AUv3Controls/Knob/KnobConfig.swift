// Copyright © 2025 Brad Howes. All rights reserved.

import AVFoundation
import SwiftUI

/**
 Shabby attempt at isolating customizations for a `KnobFeature`. Right now there is a 1-1 relationship between this and
 an AUParameter instance. Appearance configuration has been split out into a separate `Theme` class, but there are
 still too many details here that would be better shared across `KnobFeature` instances.
 */
public struct KnobConfig: Equatable, Sendable {
  public static let `default` = KnobConfig()

  /// How long to show the value in the knob's label
  public let controlShowValueMilliseconds: Int

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
    self.controlShowValueMilliseconds = showValueDuration
    self.debounceMilliseconds = debounceDuration
  }
}
