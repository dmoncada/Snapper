extension Collection {
  func paired<Other: Collection>(
    with other: Other,
    stride: Int = 1,
  ) -> [(Element, Other.Element)] {
    guard
      isEmpty == false,
      other.isEmpty == false,
      stride > 0
    else { return [] }

    let otherElements = Array(other)

    return enumerated()
      .map { index, element in
        (
          element,
          otherElements[
            Swift.min(
              index / stride,
              otherElements.count - 1,
            )
          ],
        )
      }
  }
}
