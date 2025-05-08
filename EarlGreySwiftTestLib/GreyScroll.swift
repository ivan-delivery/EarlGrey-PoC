// Created on 23.09.2020. Copyright © 2020 Foodora. All rights reserved.

import Foundation

public typealias GreyScrollOffset = CGFloat

extension GreyScrollOffset {
  static let contentEdge = CGFloat.greatestFiniteMagnitude
  static let defaultStepOffset = CGFloat(400)
}

public enum GreyScroll {
  // swiftlint:disable:next identifier_name
  case up(stepOffset: GreyScrollOffset = .defaultStepOffset)
  case down(stepOffset: GreyScrollOffset = .defaultStepOffset)
  case left(stepOffset: GreyScrollOffset = .defaultStepOffset)
  case right(stepOffset: GreyScrollOffset = .defaultStepOffset)

  public var greyAction: GREYAction {
    switch self {
    case let .up(stepOffset):
      return stepOffset == .contentEdge ? grey_scrollToContentEdge(.top) : grey_scrollInDirection(.up, stepOffset)
    case let .down(stepOffset):
      return stepOffset == .contentEdge ? grey_scrollToContentEdge(.bottom) : grey_scrollInDirection(.down, stepOffset)
    case let .left(stepOffset):
      return stepOffset == .contentEdge ? grey_scrollToContentEdge(.left) : grey_scrollInDirection(.left, stepOffset)
    case let .right(stepOffset):
      return stepOffset == .contentEdge ? grey_scrollToContentEdge(.right) : grey_scrollInDirection(.right, stepOffset)
    }
  }
}

extension GreyScroll {
  init(direction: GREYDirection, stepOffset: GreyScrollOffset = .defaultStepOffset) {
    switch direction {
    case .up: self = .up(stepOffset: stepOffset)
    case .down: self = .down(stepOffset: stepOffset)
    case .left: self = .left(stepOffset: stepOffset)
    case .right: self = .right(stepOffset: stepOffset)
    @unknown default: fatalError("Unknown case for GREYDirection")
    }
  }
}
