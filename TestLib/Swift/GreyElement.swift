// Created on 23.09.2020. Copyright © 2020 Foodora. All rights reserved.

import Foundation

protocol GreyElement {
  var greyMatcher: GREYMatcher { get }
}

extension GreyElement {
  var not: GreyElement {
    GreyCustomElement(with: grey_not(greyMatcher))
  }

  var ancestor: GreyElement {
    GreyCustomElement(with: grey_ancestor(greyMatcher))
  }

  var descendant: GreyElement {
    GreyCustomElement(with: grey_descendant(greyMatcher))
  }
}

extension String: GreyElement {
  var greyMatcher: GREYMatcher { return grey_accessibilityID(self) }
}

struct GreyClassElement: GreyElement {
  let greyMatcher: GREYMatcher

  init(with className: String) {
    self.greyMatcher = grey_kindOfClassName(className)
  }

  init(with classType: AnyClass) {
    self.greyMatcher = grey_kindOfClass(classType)
  }
}

struct GreyCustomElement: GreyElement {
  let greyMatcher: GREYMatcher

  init(with matcher: GREYMatcher) {
    self.greyMatcher = matcher
  }
}

struct GreyCompoundElement: GreyElement {
  let greyMatcher: GREYMatcher

  init(with elements: [GreyElement]) {
    self.greyMatcher = grey_allOf(elements.map(\.greyMatcher).greyMatchersNSArray)
  }
}

struct GreyAncestorElement: GreyElement {
  let greyMatcher: GREYMatcher

  init(ancestor: GreyElement) {
    self.greyMatcher = grey_ancestor(ancestor.greyMatcher)
  }
}

struct GreyTableCellElement: GreyElement {
  let greyMatcher: GREYMatcher

  init(withText text: String) {
    self.greyMatcher = grey_allOf(
      [
        GreyTableCellElement.greyCellMatcher,
        grey_descendant(grey_containsText(text)),
        grey_minimumVisiblePercent(0.1)
      ].greyMatchersNSArray
    )
  }

  init(withDescendant descendant: GreyElement) {
    self.greyMatcher = grey_allOf(
      [
        GreyTableCellElement.greyCellMatcher,
        grey_descendant(descendant.greyMatcher),
        grey_minimumVisiblePercent(0.1)
      ].greyMatchersNSArray
    )
  }

  init(withText text: String, withPrefix prefix: String) {
    self.greyMatcher = grey_allOf(
      [
        GreyTableCellElement.greyCellMatcher,
        grey_accessibilityID_prefix(prefix),
        grey_descendant(grey_containsText(text)),
        grey_minimumVisiblePercent(0.1)
      ].greyMatchersNSArray
    )
  }

  private static var greyCellMatcher: GREYMatcher {
    grey_anyOf(
      [
        grey_kindOfClass(UITableViewCell.self),
        grey_kindOfClass(UICollectionViewCell.self)
      ].greyMatchersNSArray
    )
  }
}

struct GreyPrefixedElement: GreyElement {
  let greyMatcher: GREYMatcher

  init(_ prefix: String) {
    self.greyMatcher = grey_accessibilityID_prefix(prefix)
  }
}

struct GreyAccessibilityLabel: GreyElement {
  let greyMatcher: GREYMatcher

  init(withText text: String) {
    self.greyMatcher = grey_accessibilityLabel(text)
  }
}
