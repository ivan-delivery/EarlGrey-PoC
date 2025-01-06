//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+AnimationsTest.h"
#import "BaseIntegrationTest.h"

/** A category to expose internal testing only methods. */
@interface UIView (Test)
+ (void)printAnimationsBlockPointer:(BOOL)printPointer;
@end

@interface AnimationsTest : BaseIntegrationTest
@end

@implementation AnimationsTest {
  /** The original interaction timeout to reset at the end of a test case. */
  double _originalTimeout;
}

- (void)setUp {
  [super setUp];
  _originalTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [self openTestViewNamed:@"Animations"];
}

- (void)tearDown {
  [[GREYConfiguration sharedConfiguration] setValue:@(_originalTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [super tearDown];
}

- (void)testUIViewAnimation {
  [[[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"UIViewAnimationControl")]
      performAction:GREYTap()] assertWithMatcher:GREYButtonTitle(@"Started")];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"UIView animation finished")];
}

- (void)testPausedAnimations {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Stopped")];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationControl")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Paused")];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationControl")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYNotVisible()];
}

- (void)testAnimationsNotPresentStringInHierarchyOnUnrelatedFailure {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Stopped")];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"GarbageValue")]
      assertWithMatcher:GREYNotNil()
                  error:&error];
  NSString *animationHeaderString = @"**** Currently Animating Elements: ****";
  NSString *noAnimatingElementsString = @"**** No Animating Views Found. ****";
  XCTAssertNotNil(error);
  XCTAssertTrue([error.description containsString:noAnimatingElementsString]);
  XCTAssertFalse([error.description containsString:animationHeaderString]);
}

/**
 * Checks the error description to ensure animation info for the animation on a UIView's immediate
 * layer is added.
 */
- (void)testAnimatingElementInfoForAnimatingView {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Stopped")];
  [[GREYConfiguration sharedConfiguration] setValue:@(0.5)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationControl")]
      performAction:GREYTap()];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Paused")
                  error:&error];
  XCTAssertNotNil(error);

  NSString *animationHeaderString = @"**** Currently Animating Elements: ****";
  NSString *animationViewString = @"UIView: <UIView";
  NSString *animationInfoString = @"AnimationKey: moveView withAnimation: <CABasicAnimation: ";
  NSString *windowInfoString = @"UIView: <UIWindow:";
  XCTAssertTrue([error.description containsString:animationHeaderString]);
  XCTAssertTrue([error.description containsString:animationViewString]);
  XCTAssertTrue([error.description containsString:animationInfoString]);
  XCTAssertFalse([error.description containsString:windowInfoString]);
}

/**
 * Checks the error description to ensure animation info for animations added to  the sublayers of
 * different view's hierarchy.
 */
- (void)testAnimatingElementInfoForSingleAnimatingSublayer {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Stopped")];
  UIWindow *mainWindow =
      [[[GREY_REMOTE_CLASS_IN_APP(UIApplication) sharedApplication] windows] firstObject];
  UIView *viewWithAnimatingSublayer = [[GREYHostApplicationDistantObject sharedInstance]
      viewWithAnimatingSublayerAddedToView:mainWindow
                                forKeyPath:@"anim0"];
  [[GREYConfiguration sharedConfiguration] setValue:@(0.5)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Paused")
                  error:&error];
  XCTAssertNotNil(error);
  NSString *animationHeaderString = @"**** Currently Animating Elements: ****";
  NSString *animationViewString = @"UIView: <UIView";
  NSString *animationInfoString = @"AnimationKey: anim0 withAnimation: <CABasicAnimation: ";
  NSString *windowInfoString = @"UIView: <UIWindow:";
  XCTAssertTrue([error.description containsString:animationHeaderString]);
  XCTAssertTrue([error.description containsString:animationViewString]);
  XCTAssertTrue([error.description containsString:animationInfoString]);
  XCTAssertFalse([error.description containsString:windowInfoString]);
  [viewWithAnimatingSublayer removeFromSuperview];
}

/**
 * Checks the error description to ensure animation info for animations added to the sublayers in
 * the same view's hierarchy.
 */
- (void)testAnimatingElementInfoTwoDifferentUIViewAnimatingSublayers {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Stopped")];
  UIWindow *mainWindow =
      [[[GREY_REMOTE_CLASS_IN_APP(UIApplication) sharedApplication] windows] firstObject];
  UIView *viewWithAnimatingSublayer0 = [[GREYHostApplicationDistantObject sharedInstance]
      viewWithAnimatingSublayerAddedToView:mainWindow
                                forKeyPath:@"anim0"];
  UIView *viewWithAnimatingSublayer1 = [[GREYHostApplicationDistantObject sharedInstance]
      viewWithAnimatingSublayerAddedToView:mainWindow
                                forKeyPath:@"anim1"];
  [[GREYConfiguration sharedConfiguration] setValue:@(0.5)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Paused")
                  error:&error];
  XCTAssertNotNil(error);
  NSString *windowInfoString = @"UIView: <UIWindow:";
  NSString *animationInfoString0 = @"AnimationKey: anim0 withAnimation: <CABasicAnimation: ";
  XCTAssertTrue([error.description containsString:animationInfoString0]);
  NSString *animationInfoString1 = @"AnimationKey: anim1 withAnimation: <CABasicAnimation: ";
  XCTAssertTrue([error.description containsString:animationInfoString1]);
  XCTAssertFalse([error.description containsString:windowInfoString]);
  [viewWithAnimatingSublayer0 removeFromSuperview];
  [viewWithAnimatingSublayer1 removeFromSuperview];
}

/**
 * Checks the error description to ensure animation info for sublayers is added.
 */
- (void)testAnimatingElementInfoOneUIViewWithSubViewAnimations {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Stopped")];
  UIWindow *mainWindow =
      [[[GREY_REMOTE_CLASS_IN_APP(UIApplication) sharedApplication] windows] firstObject];
  UIView *viewWithAnimatingSublayer0 = [[GREYHostApplicationDistantObject sharedInstance]
      viewWithAnimatingSublayerAddedToView:mainWindow
                                forKeyPath:@"anim0"];
  UIView *viewWithAnimatingSublayer1 = [[GREYHostApplicationDistantObject sharedInstance]
      viewWithAnimatingSublayerAddedToView:viewWithAnimatingSublayer0
                                forKeyPath:@"anim1"];
  [[GREYConfiguration sharedConfiguration] setValue:@(0.5)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Paused")
                  error:&error];
  XCTAssertNotNil(error);
  NSString *windowInfoString = @"UIView: <UIWindow:";
  NSString *animationInfoString0 = @"AnimationKey: anim0 withAnimation: <CABasicAnimation: ";
  XCTAssertTrue([error.description containsString:animationInfoString0]);
  NSString *animationInfoString1 = @"AnimationKey: anim1 withAnimation: <CABasicAnimation: ";
  XCTAssertTrue([error.description containsString:animationInfoString1]);
  XCTAssertFalse([error.description containsString:windowInfoString]);
  [viewWithAnimatingSublayer0 removeFromSuperview];
  [viewWithAnimatingSublayer1 removeFromSuperview];
}

/** Verifies EarlGrey synchronizes with UIView animations filed concurrently. */
- (void)testMultipleConcurrentAnimationTriggeredWithUIView {
  UIWindow *mainWindow = [GREY_REMOTE_CLASS_IN_APP(GREYUILibUtils) window];

  UIView *slowerAnimatedView = [[GREY_REMOTE_CLASS_IN_APP(UIView) alloc] init];
  [mainWindow addSubview:slowerAnimatedView];
  __block BOOL slowerAnimationCompleted = NO;
  [GREY_REMOTE_CLASS_IN_APP(UIView) animateWithDuration:0.1
      delay:0.5
      options:UIViewAnimationOptionAllowUserInteraction
      animations:^{
        slowerAnimatedView.alpha = 0.0;
      }
      completion:^(BOOL finished) {
        slowerAnimationCompleted = YES;
        [slowerAnimatedView removeFromSuperview];
      }];

  UIView *fasterAnimatedView = [[GREY_REMOTE_CLASS_IN_APP(UIView) alloc] init];
  [mainWindow addSubview:fasterAnimatedView];
  __block BOOL fasterAnimationCompleted = NO;
  [GREY_REMOTE_CLASS_IN_APP(UIView) animateWithDuration:0.1
      delay:0.1
      options:UIViewAnimationOptionAllowUserInteraction
      animations:^{
        fasterAnimatedView.alpha = 0.0;
      }
      completion:^(BOOL finished) {
        fasterAnimationCompleted = YES;
        [fasterAnimatedView removeFromSuperview];
      }];

  GREYWaitForAppToIdle(@"app should be idle");
  XCTAssertTrue(slowerAnimationCompleted);
  XCTAssertTrue(fasterAnimationCompleted);
}

/** Test whether or not EarlGrey synchronizes with chained UIView animation. */
- (void)testChainedAnimation {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Start UIView Chained Animation")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"viewToToggle")]
      assertWithMatcher:GREYNotVisible()];
}

- (void)testBeginEndIgnoringEvents {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"BeginIgnoringEvents")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"EndIgnoringEvents")];
}

- (void)testDelayedExecution {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Perform Delayed Execution")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"delayedLabelStatus")]
      assertWithMatcher:GREYText(@"Executed Twice!")];
}

/**
 * Ensures that when an animation fails, the error description contains the block's path.
 */
- (void)testErrorContainsBlockInformation {
  if (@available(iOS 13, *)) {
    [GREY_REMOTE_CLASS_IN_APP(UIView) printAnimationsBlockPointer:YES];
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"UIViewAnimationControl")]
        performAction:GREYTap()];
    [[GREYConfiguration sharedConfiguration] setValue:@(0)
                                         forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
    NSError *error;
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
        assertWithMatcher:GREYText(@"UIView animation finished")
                    error:&error];
#if TARGET_OS_SIMULATOR
    NSString *buttonBlockInfo = @"_beginTitleAnimation]_block_invoke";
    XCTAssertTrue([error.debugDescription containsString:buttonBlockInfo],
                  @"Should contain Button Animation Block");
#endif
    NSString *targetBlockInfo =
        @"-[AnimationViewController UIViewAnimationControlClicked:]_block_invoke";
    XCTAssertTrue([error.debugDescription containsString:targetBlockInfo],
                  @"Should contain Button Animation Target Block");
    [GREY_REMOTE_CLASS_IN_APP(UIView) printAnimationsBlockPointer:NO];
  } else {
    XCTSkip(@"b/200649728: Skipped as block pointers are only printed for post iOS 13+.");
  }
}

@end
