extension ClosedRange {

  /**
   Return a value that is always within our bounds.

   - if the value is less than our lower bound return the lower bound
   - if the value is greater than our upper bound return the upper bound
   - otherwise return the original value

   - parameter value: the value to clamp
   - returns: the bounded value
   */
  func clamp(_ value: Bound) -> Bound {
    lowerBound > value ? lowerBound : (upperBound < value ? upperBound : value)
  }
}
