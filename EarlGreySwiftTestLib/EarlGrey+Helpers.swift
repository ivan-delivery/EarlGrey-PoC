// Created on 05/06/2020. Copyright © 2020 Foodora. All rights reserved.

import Foundation

extension EarlGrey {
  @discardableResult
  public static func on(_ matcher: GREYMatcher, file: StaticString = #file, line: UInt = #line) -> GREYInteraction {
    on(matcher, grey_minimumVisiblePercent(0.1), file: file, line: line)
  }

  public static func on(_ matchers: GREYMatcher..., file: StaticString = #file, line: UInt = #line) -> GREYInteraction {
    return selectElement(
      with: grey_allOf(
        NSArray(array: matchers) as! [GREYMatcher]
      ),
      file: file,
      line: line
    ).atIndex(0)
  }

  public static func on(
    _ matcher: GREYMatcher,
    of elementClass: AnyClass,
    file: StaticString = #file,
    line: UInt = #line
  ) -> GREYInteraction {
    return selectElement(
      with: grey_allOf(
        NSArray(
          array: [
            matcher,
            grey_kindOfClass(elementClass)
          ]
        ) as! [GREYMatcher]
      )
    ).atIndex(0)
  }

  public static func onCell(
    text: String,
    at index: Int = 0,
    file: StaticString = #file,
    line: UInt = #line
  ) -> GREYInteraction {
    return selectElement(
      with: grey_allOf(
        NSArray(
          array: [
            grey_kindOfClass(UITableViewCell.self),
            grey_descendant(grey_containsText(text)),
            grey_minimumVisiblePercent(0.1)
          ]
        ) as! [GREYMatcher]
      )
    ).atIndex(UInt(index))
  }

  public static func onCollectionCell(
    text: String,
    at index: Int = 0,
    file: StaticString = #file,
    line: UInt = #line
  ) -> GREYInteraction {
    return selectElement(
      with: grey_allOf(
        NSArray(
          array: [
            grey_kindOfClass(UICollectionViewCell.self),
            grey_descendant(grey_getAccessibilityID(text)),
            grey_minimumVisiblePercent(0.1)
          ]
        ) as! [GREYMatcher]
      )
    ).atIndex(UInt(index))
  }

  public static func waitForEnabled(
    _ matcher: GREYMatcher,
    shouldFail: Bool = true,
    timeout: TimeInterval = 30,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    var error: NSError?
    let conditionFulfilled = GREYCondition(name: "\(file):\(line)") {
      error = nil // EarlGrey won't set it to nil when there is no error
      self.on(matcher).assert(grey_interactable(), error: &error)
      return error == nil
    }.wait(withTimeout: timeout)
    var reason = "\(file):\(line) - Didn't find element matching"
    reason += " \(matcher) within \(timeout) seconds"
    reason += " Error: \(error?.localizedDescription ?? "")"
    GREYAssertTrue(conditionFulfilled, reason)
  }

  public static func waitForVisible(
    _ matcher: GREYMatcher,
    shouldFail: Bool = true,
    timeout: TimeInterval = 30,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    var error: NSError?
    let conditionFulfilled = GREYCondition(name: "\(file):\(line)") {
      error = nil // EarlGrey won't set it to nil when there is no error
      self.on(matcher).assert(grey_sufficientlyVisible(), error: &error)
      return shouldFail ? error == nil : true
    }.wait(withTimeout: timeout)
    var reason = "\(file):\(line) - Didn't find element matching"
    reason += " \(matcher) within \(timeout) seconds"
    reason += " Error: \(error?.localizedDescription ?? "")"
    GREYAssertTrue(conditionFulfilled, reason)
  }

  public static func isVisible(
    _ matcher: GREYMatcher,
    timeout: TimeInterval,
    file: StaticString = #file,
    line: UInt = #line
  ) -> Bool {
    var error: NSError?
    let isVisible = GREYCondition(name: "\(file):\(line)") {
      error = nil // EarlGrey won't set it to nil when there is no error
      self.on(matcher).assert(grey_sufficientlyVisible(), error: &error)
      return error == nil
    }.wait(withTimeout: timeout)
    return isVisible
  }

  public static func waitUntilHidden(
    _ matcher: GREYMatcher,
    timeout: TimeInterval = 30,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    var error: NSError?
    let conditionFulfilled = GREYCondition(name: "\(file):\(line)") {
      error = nil // EarlGrey won't set it to nil when there is no error
      self.on(matcher).assert(grey_notVisible(), error: &error)
      return error == nil
    }.wait(withTimeout: timeout)
    var reason = "\(file):\(line) - Didn't find element matching"
    reason += " \(matcher) within \(timeout) seconds"
    reason += " Error: \(error?.localizedDescription ?? "")"
    GREYAssertTrue(conditionFulfilled, reason)
  }
}

public func grey_containsText(_ text: String) -> GREYMatcher {
  let matcherBlock: GREYMatchesBlock = { element -> Bool in
    let element = element as AnyObject
    let selector = #selector(getter: UILabel.text)
    guard element.responds(to: selector) else { return false }
    guard let viewText = element.perform(selector)?.takeUnretainedValue() as? String else { return false }

    return viewText.localizedCaseInsensitiveContains(text)
  }

  let descriptionBlock: GREYDescribeToBlock = { description in
    description.appendText("containsText('\(text)')")
  }
  let classMatchers = grey_anyOf(
    NSArray(
      array: [
        grey_kindOfClass(UILabel.self),
        grey_kindOfClass(UITextField.self),
        grey_kindOfClass(UITextView.self)
      ]
    ) as! [GREYMatcher]
  )

  return grey_allOf(
    NSArray(
      array: [
        classMatchers,
        GREYElementMatcherBlock(matchesBlock: matcherBlock, descriptionBlock: descriptionBlock)
      ]
    ) as! [GREYMatcher]
  )
}

public class GreyLabelContainer {
  var text = ""
}

public func grey_getAccessibilityLabel(of elementMatcher: GREYMatcher, container: GreyLabelContainer) -> GREYMatcher {
  let matcherBlock: GREYMatchesBlock = { element -> Bool in
    let element = element as AnyObject
    let selector = #selector(UIView.accessibilityLabel)
    guard element.responds(to: selector) else { return false }
    guard let viewText = element.perform(selector)?.takeUnretainedValue() as? String else { return false }
    container.text = viewText
    return true
  }
  let descriptionBlock: GREYDescribeToBlock = { description in
    description.appendText("getAccessibilityLabel()")
  }
  return grey_allOf(
    NSArray(
      array: [
        elementMatcher,
        GREYElementMatcherBlock(matchesBlock: matcherBlock, descriptionBlock: descriptionBlock)
      ]
    ) as! [GREYMatcher]
  )
}

public func grey_getText(of elementMatcher: GREYMatcher, container: GreyLabelContainer) -> GREYMatcher {
  let matcherBlock: GREYMatchesBlock = { element -> Bool in
    let element = element as AnyObject
    let selector = #selector(getter: UILabel.text)
    guard element.responds(to: selector) else { return false }
    guard let viewText = element.perform(selector)?.takeUnretainedValue() as? String else { return false }
    container.text = viewText
    return true
  }

  let descriptionBlock: GREYDescribeToBlock = { description in
    description.appendText("getText()")
  }

  let classMatchers = grey_anyOf(
    NSArray(
      array: [
        grey_kindOfClass(UILabel.self),
        grey_kindOfClass(UITextField.self),
        grey_kindOfClass(UITextView.self),
        grey_kindOfClass(UIControl.self)
      ]
    ) as! [GREYMatcher]
  )

  return grey_allOf(
    NSArray(
      array: [
        elementMatcher,
        classMatchers,
        GREYElementMatcherBlock(matchesBlock: matcherBlock, descriptionBlock: descriptionBlock)
      ]
    ) as! [GREYMatcher]
  )
}

public func grey_accessibilityID_prefix(_ prefix: String) -> GREYMatcher {
  let matches: GREYMatchesBlock = { (element: Any!) -> Bool in
    let object = element as AnyObject?
    return object?.accessibilityIdentifier?.starts(with: prefix) ?? false
  }

  let description: GREYDescribeToBlock = { (description: GREYDescription!) -> Void in
    guard let description = description else {
      return
    }
    description.appendText("accessibilityID_prefix('\(prefix)')")
  }

  return GREYElementMatcherBlock(matchesBlock: matches, descriptionBlock: description)
}

public func grey_getAccessibilityID(_ accessibilityId: String) -> GREYMatcher {
  let matches: GREYMatchesBlock = { (element: Any!) -> Bool in
    let object = element as AnyObject?
    return object?.accessibilityIdentifier?.contains(accessibilityId) ?? false
  }

  let description: GREYDescribeToBlock = { (description: GREYDescription!) -> Void in
    guard let description = description else {
      return
    }
    description.appendText("accessibilityID('\(accessibilityId)')")
  }

  return GREYElementMatcherBlock(matchesBlock: matches, descriptionBlock: description)
}

public final class AccessibilityIDsCollection {
  fileprivate(set) var accessibilityIDs = [String]()
}

// EarlGrey is returning cells that are hidden
// If I'm adding isVisible assertion to matchers - it freeze whole test
// That's why I'm using this workaround withcheck if all parents are visible
public func grey_collectAccessibilityIDs(
  for matcher: GREYMatcher,
  numberOfElements: Int,
  container: AccessibilityIDsCollection
) -> GREYMatcher {
  var counter = numberOfElements
  let matches: GREYMatchesBlock = { (element: Any) -> Bool in
    let object = element as AnyObject
    guard matcher.matches(element),
          let accessibilityId = object.accessibilityIdentifier,
          let unwrappedAccessibilityId = accessibilityId,
          isAllParentsVisible(of: object) // EarlGrey returns cells that are hidden, need to skip them
    else {
      return false
    }
    if counter > 0,
       !container.accessibilityIDs.contains(unwrappedAccessibilityId) {
      container.accessibilityIDs.append(unwrappedAccessibilityId)
      counter -= 1
    }
    return counter == 0
  }

  let description: GREYDescribeToBlock = { (description: GREYDescription!) -> Void in
    guard let description = description else {
      return
    }
    description.appendText("collectAccessibilityIDs")
  }

  return GREYElementMatcherBlock(matchesBlock: matches, descriptionBlock: description)
}

private func isAllParentsVisible(of object: AnyObject) -> Bool {
  guard
    let superview = object.superview,
    let unwrappedSuperview = superview
  else {
    return true
  }
  if unwrappedSuperview.isHidden == true {
    return false
  } else {
    return isAllParentsVisible(of: unwrappedSuperview)
  }
}
