// Created on 23.09.2020. Copyright © 2020 Foodora. All rights reserved.

import Foundation

public indirect enum GreyAssertion {
  case isEnabled
  case isDisabled
  case isSelected
  case isInteractable
  case isHidden
  case isMinimallyVisible
  case isSufficientlyVisible
  case isControlSelected // works only for classes inherited from UIControl. Will not work for table/collection cells
  case isVisible(percentage: CGFloat)
  case isScrolledToEdge(edge: GREYContentEdge)
  case block(_ block: GREYMatchesBlock)
  case all(_ matchers: [GreyAssertion])
  case any(_ matchers: [GreyAssertion])
  case custom(_ matcher: GREYMatcher)
  case textNotEqual(_ text: String)
  case textIsEqual(_ text: String)
  case containsText(_ text: String)
  case notContainsText(_ text: String)
  case descendantContainsText(_ text: String)
  case progress(_ progress: Double)
  case isNil
  case isNotNil

  public var greyMatcher: GREYMatcher {
    switch self {
    case .isEnabled:
      return grey_enabled()
    case .isDisabled:
      return grey_not(grey_enabled())
    case .isSelected:
      return grey_selected()
    case .isInteractable:
      return grey_interactable()
    case .isMinimallyVisible:
      return grey_minimumVisiblePercent(0.1)
    case .isSufficientlyVisible:
      return grey_minimumVisiblePercent(0.75)
    case .isHidden:
      return grey_notVisible()
    case .isControlSelected:
      return grey_selected()
    case let .isScrolledToEdge(edge):
      return grey_scrolledToContentEdge(edge)
    case let .isVisible(percentage):
      return grey_minimumVisiblePercent(percentage)
    case let .all(matchers):
      return grey_allOf(matchers.greyMatchersNSArray)
    case let .any(matchers):
      return grey_anyOf(matchers.greyMatchersNSArray)
    case let .block(block):
      return GREYElementMatcherBlock(matchesBlock: block, descriptionBlock: { $0.appendText(".matchBlock") })
    case let .custom(matcher):
      return matcher
    case let .textIsEqual(text):
      return GREYElementMatcherBlock(
        matchesBlock: { item in
          (item as? NSObjectProtocol)?.getTextUsingSelector() == text
        },
        descriptionBlock: { description in
          description.appendText(".textIsEqual.\(text)")
        }
      )
    case let .textNotEqual(text):
      return GREYElementMatcherBlock(
        matchesBlock: { item in
          let currentText = (item as? NSObjectProtocol)?.getTextUsingSelector()
          return currentText != text
        },
        descriptionBlock: { description in
          description.appendText(".textNotEqual.\(text)")
        }
      )
    case let .containsText(text):
      return GREYElementMatcherBlock(
        matchesBlock: { item in
          let currentText = (item as? NSObjectProtocol)?.getTextUsingSelector()
          return currentText?.contains(text) ?? false
        },
        descriptionBlock: { description in
          description.appendText(".containsText.\(text)")
        }
      )
    case let .notContainsText(text):
      return GREYElementMatcherBlock(
        matchesBlock: { item in
          guard let currentText = (item as? NSObjectProtocol)?.getTextUsingSelector() else { return false }
          return !currentText.contains(text)
        },
        descriptionBlock: { description in
          description.appendText(".notContainsText.\(text)")
        }
      )
    case let .descendantContainsText(text):
      return grey_descendant(grey_containsText(text))
    case let .progress(progress):
      return grey_progress(grey_equalTo(progress))
    case .isNil:
      return grey_nil()
    case .isNotNil:
      return grey_notNil()
    }
  }
}

private extension NSObjectProtocol {
  func getTextUsingSelector() -> String? {
    let selector = NSSelectorFromString("text")
    return responds(to: selector) ? perform(selector)?.takeUnretainedValue() as? String : nil
  }
}

private extension Collection where Element == GreyAssertion {
  var greyMatchersNSArray: [GREYMatcher] {
    map { $0.greyMatcher }.greyMatchersNSArray
  }
}
