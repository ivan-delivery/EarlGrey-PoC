// Created on 23.09.2020. Copyright © 2020 Foodora. All rights reserved.

import Foundation

// A prologue to using condition's.wait() function
//
// since wait() uses internally while {} loop with Thread.sleep() it
// throttles CPU like crazy if we provide poll interval 0
// and if you call wait() with default poll inteval
// it is exactly Zero.
// therefore,we use more-less sane sleep (pollInterval) value
// to let the condition satisfy with pretty good granularity
// while keeping CPU less throttled
private let defaultPollInterval: TimeInterval = 0.05

extension EarlGrey {
  @available(*, deprecated, message: "Use EarlGrey.on(element).assert(assertion, within: interval)")
  static func expect(
    within timeout: TimeInterval,
    on element: GreyElement,
    to assertion: GreyAssertion
  ) throws {
    let conditionName = "Wait on \(element.greyMatcher.description) for \(assertion.greyMatcher.description)"
    var error: NSError?
    let condition = GREYCondition(name: conditionName) {
      error = nil // EarlGrey won't set it to nil when there is no error
      self.on(element).assert(assertion.greyMatcher, error: &error)
      return error == nil
    }
    _ = condition?.wait(withTimeout: timeout, pollInterval: defaultPollInterval)
    try (error?.normalizedError).throwIfNotNil()
  }

  @available(*, deprecated, message: "Use EarlGrey.on(element).check(assertion, within: interval)")
  static func wait(
    within timeout: TimeInterval,
    on element: GreyElement,
    to assertion: GreyAssertion
  ) -> Bool {
    let conditionName = "Wait on \(element.greyMatcher.description) for \(assertion.greyMatcher.description)"
    var error: NSError?
    let condition = GREYCondition(name: conditionName) {
      error = nil // EarlGrey won't set it to nil when there is no error
      self.on(element).assert(assertion.greyMatcher, error: &error)
      return error == nil
    }
    _ = condition?.wait(withTimeout: timeout, pollInterval: defaultPollInterval)
    return error == nil
  }

  static func on(_ element: GreyElement, at index: Int = 0) -> GREYInteraction {
    let assertion = GreyAssertion.all([.custom(element.greyMatcher), .isMinimallyVisible])
    return selectElement(with: assertion.greyMatcher).atIndex(UInt(index))
  }

  static func on(_ elements: GreyElement..., visibility: GreyElementVisibility = .minimal) -> GREYInteraction {
    var assertions = elements.map { GreyAssertion.custom($0.greyMatcher) }
    assertions.append(.custom(visibility.greyMatcher))
    return on(assertions)
  }

  static func on(_ matcher: GREYMatcher..., visibility: GreyElementVisibility) -> GREYInteraction {
    var assertions = matcher.map { GreyAssertion.custom($0) }
    assertions.append(.custom(visibility.greyMatcher))
    return on(assertions)
  }

  private static func on(_ assertions: [GreyAssertion]) -> GREYInteraction {
    selectElement(with: GreyAssertion.all(assertions).greyMatcher).atIndex(0)
  }

  static func on(_ element: GreyElement, of elementClass: AnyClass) -> GREYInteraction {
    on(GreyCompoundElement(with: [element, GreyClassElement(with: elementClass)]))
  }
}

extension GREYInteraction {
  public func getTextOfDescendant() throws -> String {
    var text: String = ""
    var error: NSError?
    let selector = NSSelectorFromString("text")
    let block: GREYMatchesBlock = { item -> Bool in
      let item = item as AnyObject
      guard item.responds(to: selector),
            let textFromItem = item.perform(selector)?.takeUnretainedValue() as? String else {
        return false
      }
      text = textFromItem
      return true
    }
    assert(
      grey_descendant(
        GREYElementMatcherBlock(matchesBlock: block, descriptionBlock: { $0.appendText("getTextOfDescendant") })
      ),
      error: &error
    )
    try (error?.normalizedError).throwIfNotNil()
    return text
  }

  public func getText() throws -> String {
    var text: String = ""
    var error: NSError?
    let selector = NSSelectorFromString("text")
    let block: GREYMatchesBlock = { item -> Bool in
      let item = item as AnyObject
      guard item.responds(to: selector),
            let textFromItem = item.perform(selector)?.takeUnretainedValue() as? String else {
        return false
      }
      text = textFromItem
      return true
    }
    assert(
      GREYElementMatcherBlock(matchesBlock: block, descriptionBlock: { $0.appendText("getTextMatcher") }),
      error: &error
    )
    try (error?.normalizedError).throwIfNotNil()
    return text
  }

  public func getScrollOffset() throws -> CGPoint {
    var offset = CGPoint()
    var error: NSError?
    let selector = NSSelectorFromString("contentOffset")
    let block: GREYMatchesBlock = { item -> Bool in
      let item = item as AnyObject
      guard item.responds(to: selector) else {
        return false
      }
      // performSelector will return nil for primitive values like Bool, Int, CGPoint, etc
      // That's why we need to use getter directly
      offset = item.contentOffset
      return true
    }
    assert(
      grey_allOf([
        grey_kindOfClass(UIScrollView.self),
        GREYElementMatcherBlock(matchesBlock: block, descriptionBlock: { $0.appendText("getScrollOffset") })
      ]),
      error: &error
    )
    try (error?.normalizedError).throwIfNotNil()
    return offset
  }

  // Before iOS 13 this function returns image of size {0, 0} due to XCUITest limitations.
  @available(iOS 13, *)
  public func getImage() throws -> UIImage? {
    var image: UIImage?
    var error: NSError?
    let selector = NSSelectorFromString("image")
    let block: GREYMatchesBlock = { item -> Bool in
      let item = item as AnyObject
      guard item.responds(to: selector),
            let imageFromItem = item.perform(selector)?.takeUnretainedValue() as? UIImage else {
        return false
      }
      image = imageFromItem
      return true
    }
    assert(
      GREYElementMatcherBlock(matchesBlock: block, descriptionBlock: { $0.appendText("getImageMatcher") }),
      error: &error
    )
    try (error?.normalizedError).throwIfNotNil()
    return image
  }

  public func getSnapshot() throws -> UIImage {
    var image: UIImage?
    var error: NSError?
    let selector = NSSelectorFromString("snapshot")
    let block: GREYMatchesBlock = { item -> Bool in
      let item = item as AnyObject
      guard item.responds(to: selector),
            let imageFromItem = item.perform(selector)?.takeUnretainedValue() as? UIImage else {
        return false
      }
      image = imageFromItem
      return true
    }
    assert(
      GREYElementMatcherBlock(matchesBlock: block, descriptionBlock: { $0.appendText("getScreenshotMatcher") }),
      error: &error
    )
    try (error?.normalizedError).throwIfNotNil()
    return image!
  }

  public func getAccessibilityIdentifier() throws -> String {
    var accessibilityIdentifier: String?
    var error: NSError?
    let selector = NSSelectorFromString("accessibilityIdentifier")
    let block: GREYMatchesBlock = { item -> Bool in
      let item = item as AnyObject
      guard item.responds(to: selector),
            let valueFromItem = item.perform(selector)?.takeUnretainedValue() as? String else {
        return false
      }
      accessibilityIdentifier = valueFromItem
      return true
    }
    assert(
      GREYElementMatcherBlock(matchesBlock: block, descriptionBlock: { $0.appendText("getAccessibilityIdentifier") }),
      error: &error
    )
    try (error?.normalizedError).throwIfNotNil()
    return accessibilityIdentifier!
  }

  public func isOn() throws -> Bool? {
    var isOn: Bool?
    var error: NSError?
    let selector = NSSelectorFromString("isOn")
    let block: GREYMatchesBlock = { item -> Bool in
      let item = item as AnyObject
      guard item.responds(to: selector) else {
        return false
      }
      // performSelector will return nil for primitive values like Bool, Int, CGPoint, etc
      // That's why we need to use getter directly
      isOn = item.isOn
      return true
    }
    assert(
      GREYElementMatcherBlock(matchesBlock: block, descriptionBlock: { $0.appendText("isOn") }),
      error: &error
    )
    try (error?.normalizedError).throwIfNotNil()
    return isOn
  }

  public func isSelected() throws -> Bool? {
    var isSelected: Bool?
    var error: NSError?
    let selector = NSSelectorFromString("isSelected")
    let block: GREYMatchesBlock = { item -> Bool in
      let item = item as AnyObject
      guard item.responds(to: selector) else {
        return false
      }
      // performSelector will return nil for primitive values like Bool, Int, CGPoint, etc
      // That's why we need to use getter directly
      isSelected = item.isSelected
      return true
    }
    assert(
      GREYElementMatcherBlock(matchesBlock: block, descriptionBlock: { $0.appendText("isSelected") }),
      error: &error
    )
    try (error?.normalizedError).throwIfNotNil()
    return isSelected
  }

  @discardableResult 
  public func assert(_ assertion: GreyAssertion, within timeout: TimeInterval = 0) throws -> Self {
    var error: NSError?

    if timeout.isZero {
      assert(assertion.greyMatcher, error: &error)
    } else {
      let conditionName = "Wait on \(description) for \(assertion.greyMatcher.description)"
      let condition = GREYCondition(name: conditionName) {
        error = nil // EarlGrey won't set it to nil when there is no error
        self.assert(assertion.greyMatcher, error: &error)
        return error == nil
      }
      _ = condition?.wait(withTimeout: timeout, pollInterval: defaultPollInterval)
    }

    try (error?.normalizedError).throwIfNotNil()
    return self
  }

  @discardableResult 
  public func check(_ assertion: GreyAssertion, within timeout: TimeInterval = 0) -> Bool {
    var error: NSError?

    if timeout.isZero {
      assert(assertion.greyMatcher, error: &error)
    } else {
      let conditionName = "Wait on \(description) for \(assertion.greyMatcher.description)"
      let condition = GREYCondition(name: conditionName) {
        error = nil // EarlGrey won't set it to nil when there is no error
        self.assert(assertion.greyMatcher, error: &error)
        return error == nil
      }
      _ = condition?.wait(withTimeout: timeout, pollInterval: defaultPollInterval)
    }

    return error == nil
  }

  @discardableResult 
  public func perform(_ action: GreyAction) throws -> Self {
    var error: NSError?
    perform(action.greyAction, error: &error)
    try (error?.normalizedError).throwIfNotNil()
    return self
  }

  @discardableResult 
  public func perform(_ action: GreyAction, withDelay delay: UInt32) throws -> Self {
    sleep(delay)
    return try perform(action)
  }

  @discardableResult 
  public func performRepeatelly(action: GreyAction, count: UInt, delay: TimeInterval) throws -> Self {
    if count == 1 {
      try perform(action)
    } else {
      for _ in 0..<count {
        _ = XCTWaiter.wait(for: [], timeout: delay)
        try perform(action)
      }
    }
    return self
  }

  @discardableResult 
  public func usingScroll(
    _ scroll: GreyScroll,
    in element: GreyElement
  ) -> Self {
    return usingSearch(action: scroll.greyAction, onElementWith: element.greyMatcher)
  }
}

private extension Optional where Wrapped == Error {
  func throwIfNotNil() throws {
    if let error = self {
      throw error
    }
  }
}

private extension Error {
  /// Normalize NSLocalizedDescriptionKey of error to fix problems with generating HTML report
  /// and to fix exception readability issue in Nimble
  var normalizedError: Error {
    let error = (self as NSError)
    // Nimble trims newline characters and error description became not readable in output
    // That's why I replace newline character "\n" with caret return character "\r"
    // xcresult has problem with generating test report if error text contains "&" symbol
    // Replace double "&&" with word "AND" first (to avoid text like AND in case of "&" usage)
    var normalizedErrorDescription = error.localizedDescription
      .replacingOccurrences(of: "\n", with: "\r")
      .replacingOccurrences(of: "&&", with: "AND")
      .replacingOccurrences(of: "&", with: "AND")

    // Remove UI Hierarchy from error description due to problems with generating report
    let viewsHierarchyTitle = "UI Hierarchy (Back to front):"
    if let viewsHierarchyTitleIndex = normalizedErrorDescription.range(of: viewsHierarchyTitle) {
      normalizedErrorDescription = String(normalizedErrorDescription[..<viewsHierarchyTitleIndex.lowerBound])
    }

    return NSError(
      domain: error.domain,
      code: error.code,
      userInfo: [NSLocalizedDescriptionKey: normalizedErrorDescription]
    )
  }
}

extension Array where Element == GREYMatcher {
  var greyMatchersNSArray: [GREYMatcher] {
    return NSArray(array: self) as! [GREYMatcher]
  }
}
