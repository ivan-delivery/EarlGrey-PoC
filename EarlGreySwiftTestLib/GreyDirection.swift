// Created on 1/7/21. Copyright © 2021 Foodora. All rights reserved.

import Foundation

extension GREYDirection {
  var toString: String {
    switch self {
    case .left:
      return "left"
    case .right:
      return "right"
    case .up:
      return "up"
    case .down:
      return "down"
    default:
      return ""
    }
  }
}
