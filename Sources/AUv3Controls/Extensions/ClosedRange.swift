extension ClosedRange {

  /**
   Return a value that is always between `lowerBound` and `upperBound` inclusive.

   - parameter value: the value to clamp
   - returns: the bounded value
   */
  @inlinable
  func clamp(_ value: Bound) -> Bound {
    lowerBound > value ? lowerBound : (upperBound < value ? upperBound : value)
  }
}
