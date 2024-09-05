// Created on 16.12.20. Copyright © 2020 Foodora. All rights reserved.

import Foundation

public enum GreyElementVisibility {
  case minimal
  case sufficient
  case percentage(CGFloat)

  var greyMatcher: GREYMatcher {
    switch self {
    case .minimal:
      return grey_minimumVisiblePercent(0.1)
    case .sufficient:
      return grey_sufficientlyVisible()
    case let .percentage(percent):
      return grey_minimumVisiblePercent(percent)
    }
  }
}
