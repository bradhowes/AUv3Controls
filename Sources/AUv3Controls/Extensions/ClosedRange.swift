// Copyright © 2025 Brad Howes. All rights reserved.

extension Comparable {

  /**
   Obtain a new value that is clamped to the given range.

   - parameter limits: the range to use
   - returns: new value
   */
  internal func clamped(to limits: ClosedRange<Self>) -> Self {
    min(max(self, limits.lowerBound), limits.upperBound)
  }
}

extension Comparable where Self: BinaryFloatingPoint {

  /**
   Obtain a normalized value (0-1.0) over the given range.

   - parameter limits: the range to use
   - returns: normalized value
   */
  internal func normalize(in limits: ClosedRange<Self>) -> Self {
    clamped(to: limits) / (limits.upperBound - limits.lowerBound)
  }
}

extension ClosedRange {

  /**
   Clamp the given value so that it is within our bounds.

   - parameter value to clamp
   - returns: new value
   */
  internal func clamp(value: Bound) -> Bound { value.clamped(to: self) }
}

extension ClosedRange where Bound: BinaryFloatingPoint {

  /**
   Normalize the given value over our bounds.

   - parameter value to normalize
   - returns: normalized value
   */
  internal func normalize(value: Bound) -> Bound { value.normalize(in: self) }
}
