//
// Copyright 2017 Google Inc.
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

#import "EarlGreyImpl.h"

#import "GREYSyntheticEvents.h"
#import "GREYKeyboard.h"
#import "GREYMatchers.h"
#import "GREYConfigKey.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYError.h"
#import "GREYAppleInternals.h"


#import "GREYElementInteractionErrorHandler.h"
#import "GREYElementInteractionProxy.h"
#import "GREYRemoteExecutor.h"
#import "GREYDefaultFailureHandler.h"
#import "XCTestCase+GREYTest.h"
#import "GREYUIWindowProvider.h"

// In tvOS, this var becomes unused.
#if TARGET_OS_IOS
/** Timeout for XCUITest actions that need the waiting API. */
static const CFTimeInterval kWaitForExistenceTimeout = 10;
#endif  // TARGET_OS_IOS

/**
 * Sets EarlGrey provided default failure handler if there's no failure handler set for the current
 * thread.
 */
static inline void SetDefaultFailureHandler(void) {
  NSDictionary<NSString *, id> *TLSDict = [[NSThread mainThread] threadDictionary];
  [TLSDict setValue:[[GREYDefaultFailureHandler alloc] init] forKey:GREYFailureHandlerKey];
}

/** Returns the current failure handler. If it's @c nil, sets the default one and returns it. */
static inline id<GREYFailureHandler> GREYGetCurrentFailureHandler(void) {
  NSDictionary<NSString *, id> *TLSDict = [[NSThread mainThread] threadDictionary];
  id<GREYFailureHandler> handler = [TLSDict valueForKey:GREYFailureHandlerKey];
  if (!handler) {
    SetDefaultFailureHandler();
    handler = [TLSDict valueForKey:GREYFailureHandlerKey];
  }
  return handler;
}

@interface GREYMatchers (GREYTest)
+ (id<GREYMatcher>)activitySheetPresentMatcher;
@end

/**
 * The root window matcher that can be set when writing tests on a multi-scene application.
 */
static id<GREYMatcher> gRootWindowMatcher;

@implementation EarlGreyImpl

/**
 * Executes the specified @block in a remote executor background queue.
 *
 * @param block The block to run in aremote executor background queue.
 */
static BOOL ExecuteSyncBlockInBackgroundQueue(BOOL (^block)(void)) {
  __block BOOL success;
  GREYExecuteSyncBlockInBackgroundQueue(^{
    success = block();
  });
  return success;
}

+ (void)load {
  // This needs to be done in load as there may be calls to GREYAssert APIs that access the failure
  // handler directy. If it's not set, they won't be able to raise an error.
  GREYGetCurrentFailureHandler();
}

+ (instancetype)invokedFromFile:(NSString *)fileName lineNumber:(NSUInteger)lineNumber {
  static EarlGreyImpl *instance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    instance = [[EarlGreyImpl alloc] initOnce];
  });

  id<GREYFailureHandler> failureHandler = GREYGetCurrentFailureHandler();
  SEL invocationFileAndLineSEL = @selector(setInvocationFile:andInvocationLine:);
  if ([failureHandler respondsToSelector:invocationFileAndLineSEL]) {
    [failureHandler setInvocationFile:fileName andInvocationLine:lineNumber];
  }
  
  
  return instance;
}

- (instancetype)initOnce {
  self = [super init];
  return self;
}

- (id<GREYInteraction>)selectElementWithMatcher:(id<GREYMatcher>)elementMatcher {
  if (!gRootWindowMatcher) {
    return [[GREYElementInteractionProxy alloc] initWithElementMatcher:elementMatcher];
  } else {
    return [[[GREYElementInteractionProxy alloc] initWithElementMatcher:elementMatcher]
        inRoot:gRootWindowMatcher];
  }
}

- (BOOL)dismissKeyboardWithError:(NSError **)error {
  __block GREYError *dismissalError = nil;
  BOOL success = ExecuteSyncBlockInBackgroundQueue(^{
    return [GREYKeyboard dismissKeyboardWithoutReturnKeyWithError:&dismissalError];
  });
  if (!success) {
    NSString *errorDescription =
        [NSString stringWithFormat:@"Failed to dismiss keyboard: %@",
                                   dismissalError.userInfo[kErrorFailureReasonKey]];
    dismissalError = GREYErrorMake(kGREYKeyboardDismissalErrorDomain,
                                   GREYKeyboardDismissalFailedErrorCode, errorDescription);
    if (error) {
      *error = dismissalError;
    } else {
      GREYHandleInteractionError(dismissalError, nil);
    }
  }
  return success;
}

#if defined(__IPHONE_11_0)
- (BOOL)openDeepLinkURL:(NSString *)URL
        withApplication:(XCUIApplication *)application
                  error:(NSError **)error {
#if TARGET_OS_IOS
  XCUIApplication *safariApp =
      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.mobilesafari"];
  [safariApp activate];
  double timeoutInSeconds = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  BOOL success = [safariApp waitForState:XCUIApplicationStateRunningForeground
                                 timeout:timeoutInSeconds];
  I_GREYAssertTrue(success, @"Safari did not launch successfully.");
  // As Safari loads up for the first time, the URL is not clickable and we have to wait for the app
  // to be hittable for it.
  XCUIElement *safariURLBarButton = safariApp.buttons[@"URL"];
  // Safari XCUIElement with accessibilityID 'URL' is a text field if it's the first responder,
  // otherwise it's a button.
  if ([safariApp.textFields[@"Search or enter website name"] exists]) {
    [safariApp.textFields[@"Search or enter website name"] tap];
    if (@available(iOS 15.0, *)) {
      XCUIElement *swipeTutorialButton =
          safariApp.otherElements[@"UIContinuousPathIntroductionView"].buttons[@"Continue"];
      if ([swipeTutorialButton waitForExistenceWithTimeout:5]) {
        [swipeTutorialButton tap];
      }
    }
    [safariApp.textFields[@"URL"] typeText:URL];
    [safariApp.buttons[@"Go"] tap];
  } else if ([safariApp.buttons[@"Search or enter website name"] exists]) {
    // In iOS 15.2, the "Search or enter website name" is a button, and becomes the textfield when
    // it gets focused.
    [safariApp.buttons[@"Search or enter website name"] tap];
    if (@available(iOS 15.0, *)) {
      XCUIElement *swipeTutorialButton =
          safariApp.otherElements[@"UIContinuousPathIntroductionView"].buttons[@"Continue"];
      if ([swipeTutorialButton waitForExistenceWithTimeout:5]) {
        [swipeTutorialButton tap];
      }
    }
    [safariApp.textFields[@"Search or enter website name"] typeText:URL];
    [safariApp.buttons[@"Go"] tap];
  } else if ([safariURLBarButton waitForExistenceWithTimeout:kWaitForExistenceTimeout] &&
             safariApp.hittable) {
    [safariURLBarButton tap];
    [safariApp.textFields[@"URL"] typeText:URL];
    [safariApp.buttons[@"Go"] tap];
  } else if (error) {
    *error = GREYErrorMake(kGREYDeeplinkErrorDomain, GREYDeeplinkActionFailedError,
                           @"Deeplink open action failed since URL field not present.");
  }
  XCUIElement *openButton = safariApp.buttons[@"Open"];
  if ([openButton waitForExistenceWithTimeout:kWaitForExistenceTimeout]) {
    [safariApp.buttons[@"Open"] tap];
    return YES;
  } else if (error) {
    *error = GREYErrorMake(kGREYDeeplinkErrorDomain, GREYDeeplinkActionFailedError,
                           @"Deeplink open action failed since Open Button on the app dialog for "
                           @"the deeplink not present.");
    // Reset Safari.
    [safariApp terminate];
  }
  // This is needed otherwise failed tests will stall until failure.
  [application activate];
#endif  // TARGET_OS_IOS
  return NO;
}
#endif  // defined(__IPHONE_11_0)

- (BOOL)shakeDeviceWithError:(NSError **)error {
  __block GREYError *shakeDeviceError = nil;
  BOOL success = ExecuteSyncBlockInBackgroundQueue(^{
    double timeoutInSeconds = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    void (^shakeBlock)(void) = ^{
      [GREY_REMOTE_CLASS_IN_APP(GREYSyntheticEvents) shakeDevice];
    };
    return [[GREYUIThreadExecutor sharedInstance] executeSyncWithTimeout:timeoutInSeconds
                                                                   block:shakeBlock
                                                                   error:&shakeDeviceError];
  });
  if (!success && error) {
    *error = shakeDeviceError;
  }
  return success;
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  id<GREYFailureHandler> failureHandler = GREYGetCurrentFailureHandler();
  [failureHandler handleException:exception details:details];
}

- (BOOL)isKeyboardShownWithError:(NSError **)error {
  __block GREYError *keyboardShownError = nil;
  BOOL keyboardShown = ExecuteSyncBlockInBackgroundQueue(^{
    return [GREYKeyboard keyboardShownWithError:&keyboardShownError];
  });
  // Handle keyboardShownError if any, if the app failed to idle.
  if (keyboardShownError) {
    if (error) {
      *error = keyboardShownError;
    } else {
      GREYHandleInteractionError(keyboardShownError, nil);
    }
  }
  return keyboardShown;
}

- (void)setHostApplicationCrashHandler:(nullable GREYHostApplicationCrashHandler)handler {
  [XCTestCase grey_setHostApplicationCrashHandler:handler];
}

- (void)setRemoteExecutionDispatchPolicy:(GREYRemoteExecutionDispatchPolicy)dispatchPolicy {
  GREYError *setPolicyError;
  GREYTestApplicationDistantObject *distantObject = GREYTestApplicationDistantObject.sharedInstance;
  if (![distantObject setDispatchPolicy:dispatchPolicy error:&setPolicyError]) {
    GREYHandleInteractionError(setPolicyError, nil);
  }
}

- (void)setRootMatcherForSubsequentInteractions:(nullable id<GREYMatcher>)rootWindowMatcher {
  gRootWindowMatcher = rootWindowMatcher;
}

#pragma mark - Rotation

#if TARGET_OS_IOS
- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation error:(NSError **)error {
  GREYError *syncErrorBeforeRotation;
  __block GREYError *syncErrorAfterRotation;
  BOOL success = NO;
  __block BOOL sendOrientationChangeNotification = NO;
  XCUIDevice *sharedDevice = [XCUIDevice sharedDevice];
  UIDevice *currentDevice = [GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice];
  UIInterfaceOrientation interfaceOrientation =
      [GREYConstants interfaceOrientationForDeviceOrientation:deviceOrientation];
  if (interfaceOrientation != UIInterfaceOrientationUnknown) {

    NSNotificationCenter *notificationCenter =
        [GREY_REMOTE_CLASS_IN_APP(NSNotificationCenter) defaultCenter];

    // Add an orientation change notification observer.
    [notificationCenter addObserverForName:UIDeviceOrientationDidChangeNotification
                                    object:nil
                                     queue:nil
                                usingBlock:^(NSNotification *_Nonnull note) {
                                  sendOrientationChangeNotification = YES;
                                }];
    CFTimeInterval interactionTimeout =
        GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    BOOL syncSuccessBeforeRotation =
        GREYWaitForAppToIdleWithTimeoutAndError(interactionTimeout, &syncErrorBeforeRotation);
    if (syncSuccessBeforeRotation) {
      [sharedDevice setOrientation:deviceOrientation];
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)
      if (@available(iOS 16.0, *)) {
        // no-op. There's no need to perform extra process when checking app orientation with
        // UIScene.
      } else {
        [currentDevice setOrientation:deviceOrientation animated:NO];
      }
#else
      [currentDevice setOrientation:deviceOrientation animated:NO];
#endif  // (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)

      BOOL syncSuccessAfterRotation =
          !syncErrorAfterRotation &&
          GREYWaitForAppToIdleWithTimeoutAndError(interactionTimeout, &syncErrorAfterRotation);
      if (syncSuccessAfterRotation) {
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)
        if (@available(iOS 16.0, *)) {
          UIWindowScene *scene = [[GREY_REMOTE_CLASS_IN_APP(GREYUIWindowProvider)
              keyWindowForSharedApplication] windowScene];
          GREYCondition *rotationWait =
              [GREYCondition conditionWithName:@"App Rotation Condition"
                                         block:^BOOL {
                                           return scene.effectiveGeometry.interfaceOrientation ==
                                                  interfaceOrientation;
                                         }];
          success = [rotationWait
              waitWithTimeout:GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration)];
        } else {
          success = currentDevice.orientation == deviceOrientation;
        }
#else
        success = currentDevice.orientation == deviceOrientation;
#endif  // (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)
      }
    }

    // Remove the orientation change notification observer.
    [notificationCenter removeObserver:self
                                  name:UIDeviceOrientationDidChangeNotification
                                object:nil];
  }

  if (!success) {
    NSString *errorDescription;
    NSMutableDictionary<NSString *, id> *errorDetails = [[NSMutableDictionary alloc] init];

    if (syncErrorBeforeRotation) {
      errorDetails[kErrorDetailRecoverySuggestionKey] =
          syncErrorBeforeRotation.userInfo[kErrorFailureReasonKey];
      errorDescription = @"Application did not idle before rotating.";
    } else if (syncErrorAfterRotation) {
      errorDetails[kErrorDetailRecoverySuggestionKey] =
          syncErrorAfterRotation.userInfo[kErrorFailureReasonKey];
      errorDescription =
          @"Application did not idle after rotating and before verifying the rotation.";
    } else if (!syncErrorBeforeRotation && !syncErrorAfterRotation) {
      if (interfaceOrientation == UIInterfaceOrientationUnknown) {
        errorDescription = [NSString
            stringWithFormat:
                @"Could not rotate application to orientation: %tu because the orientation is not "
                @"supported by the rotation API. The supported orientations are "
                @"UIDeviceOrientationPortrait (%tu), UIDeviceOrientationPortraitUpsideDown (%tu), "
                @"UIDeviceOrientationLandscapeLeft (%tu), UIDeviceOrientationLandscapeRight (%tu).",
                deviceOrientation, UIDeviceOrientationPortrait,
                UIDeviceOrientationPortraitUpsideDown, UIDeviceOrientationLandscapeLeft,
                UIDeviceOrientationLandscapeRight];
      } else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        errorDescription = @"Could not rotate the device to portraitUpsideDown because the hosting "
                           @"device doesn't support this orientation.";
      } else {
        UIDeviceOrientation appDeviceOrientation = currentDevice.orientation;
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)
        if (@available(iOS 16.0, *)) {
          UIWindowScene *scene = [[GREY_REMOTE_CLASS_IN_APP(GREYUIWindowProvider)
              keyWindowForSharedApplication] windowScene];
          appDeviceOrientation =
              [GREYConstants deviceOrientationForInterfaceOrientation:scene.effectiveGeometry
                                                                          .interfaceOrientation];
        }
#endif  // (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)
        errorDescription = [NSString
            stringWithFormat:@"Could not rotate application to orientation: %tu. After applying "
                             @"the orientation, either XCUIDevice orientation (%tu) or application "
                             @"orientation (%tu) doesn't match the requested orientation.",
                             deviceOrientation, sharedDevice.orientation, appDeviceOrientation];
      }
    }

    GREYError *rotationError = GREYErrorMakeWithUserInfo(kGREYSyntheticEventInjectionErrorDomain,
                                                         kGREYOrientationChangeFailedErrorCode,
                                                         errorDescription, errorDetails);
    GREYHandleInteractionError(rotationError, error);
  } else {
    // Send a notification for the orientation change to the test side since we have confirmed the
    // app has changed its orientation.
    if (sendOrientationChangeNotification) {
      [[NSNotificationCenter defaultCenter]
          postNotificationName:UIDeviceOrientationDidChangeNotification
                        object:nil];
    }
  }

  return success;
}

- (NSString *)SystemAlertTextWithError:(NSError **)error {
  return [[XCTestCase grey_currentTestCase] grey_systemAlertTextWithError:error];
}

/** Standalone API for XCTestCase::grey_systemAlertType:. */
- (GREYSystemAlertType)SystemAlertType {
  return [[XCTestCase grey_currentTestCase] grey_systemAlertType];
}

/** Standalone API for XCTestCase::grey_acceptSystemDialogWithError:. */
- (BOOL)AcceptSystemDialogWithError:(NSError **)error {
  return [[XCTestCase grey_currentTestCase] grey_acceptSystemDialogWithError:error];
}

/** Standalone API for XCTestCase::grey_denySystemDialogWithError:. */
- (BOOL)DenySystemDialogWithError:(NSError **)error {
  return [[XCTestCase grey_currentTestCase] grey_denySystemDialogWithError:error];
}

/** Standalone API for XCTestCase::grey_tapSystemDialogButtonWithText:error:. */
- (BOOL)TapSystemDialogButtonWithText:(NSString *)text error:(NSError **)error {
  return [[XCTestCase grey_currentTestCase] grey_tapSystemDialogButtonWithText:text error:error];
}

/** Standalone API for XCTestCase::grey_typeSystemAlertText:forPlaceholderText:error:. */
- (BOOL)TypeSystemAlertText:(NSString *)textToType
         forPlaceholderText:(NSString *)placeholderText
                      error:(NSError **)error {
  return [[XCTestCase grey_currentTestCase] grey_typeSystemAlertText:textToType
                                                  forPlaceholderText:placeholderText
                                                               error:error];
}

/** Standalone API for XCTestCase::grey_waitForAlertVisibility:withTimeout:. */
- (BOOL)WaitForAlertVisibility:(BOOL)visible withTimeout:(CFTimeInterval)seconds {
  return [[XCTestCase grey_currentTestCase] grey_waitForAlertVisibility:visible
                                                            withTimeout:seconds];
}

- (BOOL)activitySheetPresentWithError:(NSError **)error {
  GREYError *localError;
  XCUIApplication *currentApplication = [[XCUIApplication alloc] init];
  double timeoutInSeconds = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  BOOL result = [currentApplication.otherElements[@"ActivityListView"]
      waitForExistenceWithTimeout:timeoutInSeconds];
  // Acts as a defensive check for EarlGrey synchronization. For iOS 16, the matcher would just be
  // grey_kindOfClassName(@"_UIActivityContentCollectionView").
  [[EarlGrey selectElementWithMatcher:[GREYMatchers activitySheetPresentMatcher]]
      assertWithMatcher:[GREYMatchers matcherForNotNil]
                  error:&localError];
  if (!result) {
    localError =
        GREYErrorMake(kGREYActivitySheetHandlingErrorDomain,
                      GREYActivitySheetHandlingSheetNotPresent, @"Activity Sheet not present");
    GREYHandleInteractionError(localError, error);
    return NO;
  }
  return YES;
}

- (BOOL)activitySheetAbsentWithError:(NSError **)error {
  GREYError *localError;
  BOOL sheetAbsent = NO;
  [[EarlGrey selectElementWithMatcher:[GREYMatchers activitySheetPresentMatcher]]
      assertWithMatcher:[GREYMatchers matcherForNil]
                  error:&localError];
  if (!localError) {
    XCUIApplication *currentApplication = [[XCUIApplication alloc] init];
    sheetAbsent = ![currentApplication.otherElements[@"ActivityListView"] exists];
    if (!sheetAbsent) {
      localError =
          GREYErrorMake(kGREYActivitySheetHandlingErrorDomain,
                        GREYActivitySheetHandlingSheetNotAbsent, @"Activity Sheet not present.");
    }
  }
  if (!sheetAbsent) {
    GREYHandleInteractionError(localError, error);
  }
  return NO;
}

- (BOOL)activitySheetPresentWithURL:(NSString *)URL error:(NSError **)error NS_SWIFT_NOTHROW {
  GREYError *localError;
  BOOL sheetPresent = [self activitySheetPresentWithError:&localError];
  if (sheetPresent) {
    XCUIApplication *currentApplication = [[XCUIApplication alloc] init];
    double timeoutInSeconds = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    sheetPresent =
        [currentApplication.otherElements[URL] waitForExistenceWithTimeout:timeoutInSeconds];
  }
  if (!sheetPresent) {
    NSString *description =
        [NSString stringWithFormat:@"Activity Sheet with URL couldn't be found: %@", URL];
    localError = GREYErrorMake(kGREYActivitySheetHandlingErrorDomain,
                               GREYActivitySheetHandlingSheetWithURLNotPresent, description);
    GREYHandleInteractionError(localError, error);
    return NO;
  }
  return sheetPresent;
}

- (void)tapElementInActivitySheetWithID:(NSString *)identifier error:(NSError **)error {
  XCUIApplication *currentApplication = [[XCUIApplication alloc] init];
  XCUIElement *activitySheet = currentApplication.otherElements[@"ActivityListView"];
  XCUIElement *element = [activitySheet descendantsMatchingType:XCUIElementTypeAny][identifier];
  if ([element exists]) {
    [element tap];
    return;
  }

  NSString *description = [NSString
      stringWithFormat:@"Activity Sheet element not present with identifier: %@", identifier];
  GREYError *localError =
      GREYErrorMake(kGREYActivitySheetHandlingErrorDomain,
                    GREYActivitySheetHandlingSheetElementNotPresent, description);
  GREYHandleInteractionError(localError, error);
}

- (BOOL)tapButtonInActivitySheetWithId:(NSString *)identifier error:(NSError **)error {
  BOOL buttonPresent = [self buttonPresentInActivitySheetWithId:identifier error:error];
  if (buttonPresent) {
    XCUIApplication *currentApplication = [[XCUIApplication alloc] init];
    XCUIElement *activitySheet = currentApplication.otherElements[@"ActivityListView"];
    XCUIElementType type = XCUIElementTypeStaticText;
    if ([identifier isEqualToString:@"Close"]) {
      type = XCUIElementTypeButton;
    }
    XCUIElementQuery *activityTexts = [activitySheet descendantsMatchingType:type];
    XCUIElement *button = [activityTexts elementMatchingType:type identifier:identifier];
    [button tap];
  }
  return buttonPresent;
}

- (BOOL)buttonPresentInActivitySheetWithId:(NSString *)identifier
                                     error:(NSError **)error API_AVAILABLE(ios(17)) {
  GREYError *localError;
  BOOL sheetPresent = [self activitySheetPresentWithError:error];
  if (sheetPresent) {
    XCUIApplication *currentApplication = [[XCUIApplication alloc] init];
    XCUIElement *activitySheet = currentApplication.otherElements[@"ActivityListView"];
    XCUIElementType type = XCUIElementTypeStaticText;
    if ([identifier isEqualToString:@"Close"]) {
      type = XCUIElementTypeButton;
    }
    XCUIElementQuery *activityTexts = [activitySheet descendantsMatchingType:type];
    XCUIElement *button = [activityTexts elementMatchingType:type identifier:identifier];
    if (button && [button exists]) {
      return YES;
    } else {
      NSString *description = [NSString
          stringWithFormat:@"Activity Sheet button not present with identifier: %@", identifier];
      localError = GREYErrorMake(kGREYActivitySheetHandlingErrorDomain,
                                 GREYActivitySheetHandlingSheetButtonNotPresent, description);
      GREYHandleInteractionError(localError, error);
    }
  }
  return NO;
}

- (BOOL)closeActivitySheetWithError:(NSError **)error {
  BOOL sheetPresent = [self activitySheetPresentWithError:error];
  if (sheetPresent) {
    return [self tapButtonInActivitySheetWithId:@"Close" error:error];
  } else {
    return NO;
  }
}

#endif  // TARGET_OS_IOS

@end
