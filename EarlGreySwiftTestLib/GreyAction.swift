// Created on 23.09.2020. Copyright © 2020 Foodora. All rights reserved.

import Foundation

enum GreyAction {
  case tap
  case swipe(direction: GREYDirection)
  case typeText(_ text: String)
  case replaceText(_ text: String)
  case clearText
  case scroll(direction: GREYDirection, offset: CGFloat)
  case scrollToContentEdge(direction: GREYContentEdge)
  case swipeFast(direction: GREYDirection)
  case custom(_ action: GREYAction)

  var greyAction: GREYAction {
    switch self {
    case .tap:
      return grey_tap()
    case let .swipe(direction):
      return grey_swipeSlowInDirection(direction)
    case let .typeText(text):
      return grey_typeText(text)
    case let .replaceText(text):
      return grey_replaceText(text)
    case .clearText:
      return grey_clearText()
    case let .scroll(direction, offset):
      return grey_scrollInDirection(direction, offset)
    case let .scrollToContentEdge(direction):
      return grey_scrollToContentEdge(direction)
    case let .swipeFast(direction):
      return grey_swipeFastInDirection(direction)
    case let .custom(action):
      return action
    }
  }
}
