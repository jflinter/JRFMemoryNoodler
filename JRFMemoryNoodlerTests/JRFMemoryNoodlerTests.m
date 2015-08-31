//
//  JRFMemoryNoodlerTests.m
//  JRFMemoryNoodlerTests
//
//  Created by Jack Flintermann on 8/30/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

@import UIKit;
@import XCTest;
@import JRFMemoryNoodler;

@interface JRFMemoryNoodlerTests : XCTestCase
@end

@implementation JRFMemoryNoodlerTests

- (void)testBaseCase {
    [self checkMemoryNoodlerWithExpectation:YES shouldBeInForeground:YES didCrash:NO];
}

- (void)testCrashesDoNotTriggerOutOfMemoryWarning {
    [self checkMemoryNoodlerWithExpectation:NO shouldBeInForeground:YES didCrash:YES];
}

- (void)testAbortDoesNotTriggerOutOfMemoryWarning {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"JRFAppDidAbortKey"];
    [self checkMemoryNoodlerWithExpectation:NO shouldBeInForeground:YES didCrash:NO];
}

- (void)testTerminationDoesNotTriggerOutOfMemoryWarning {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"JRFAppWasTerminatedKey"];
    [self checkMemoryNoodlerWithExpectation:NO shouldBeInForeground:YES didCrash:NO];
}

- (void)testVersionUpgradeDoesNotTriggerOutOfMemoryWarning {
    [[NSUserDefaults standardUserDefaults] setObject:@"0.0.0" forKey:@"JRFPreviousBundleVersionKey"];
    [self checkMemoryNoodlerWithExpectation:NO shouldBeInForeground:YES didCrash:NO];
}

- (void)testOSUpgradeDoesNotTriggerOutOfMemoryWarning {
    [[NSUserDefaults standardUserDefaults] setObject:@"0.0.0" forKey:@"JRFPreviousOSVersionKey"];
    [self checkMemoryNoodlerWithExpectation:NO shouldBeInForeground:YES didCrash:NO];
}

- (void)testBackgroundingTracksProperly {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"JRFAppWasInBackgroundKey"];
    [self checkMemoryNoodlerWithExpectation:NO shouldBeInForeground:NO didCrash:YES];
}

- (void)checkMemoryNoodlerWithExpectation:(BOOL)shouldRegisterOutOfMemory
                     shouldBeInForeground:(BOOL)shouldBeInForeground
                                 didCrash:(BOOL) didCrash {
    [JRFMemoryNoodler beginMonitoringMemoryEventsWithHandler:^(BOOL wasInForeground) {
        if (shouldRegisterOutOfMemory) {
            XCTAssertEqual(shouldBeInForeground, wasInForeground, @"Application should have been in foreground but wasn't.");
        } else {
            XCTFail(@"Out of memory crash was logged, but shouldn't have been.");
        }
    } crashDetector:^BOOL{
        return didCrash;
    }];
}

@end
