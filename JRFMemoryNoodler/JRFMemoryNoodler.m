//
//  JRFMemoryNoodler.m
//  JRFMemoryNoodler
//
//  Created by Jack Flintermann on 8/30/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

@import UIKit;

#import "JRFMemoryNoodler.h"
#import "JRFPathUtilities.h"

#include <sys/stat.h>

NSString *JRFPreviousBundleVersionKey = @"JRFPreviousBundleVersionKey";
NSString *JRFAppWasTerminatedKey = @"JRFAppWasTerminatedKey";
NSString *JRFAppWasInBackgroundKey = @"JRFAppWasInBackgroundKey";
NSString *JRFAppDidCrashKey = @"JRFAppDidCrashKey";
NSString *JRFPreviousOSVersionKey = @"JRFPreviousOSVersionKey";
static char *intentionalQuitPathname;

@implementation JRFMemoryNoodler

+ (void)beginMonitoringMemoryEventsWithHandler:(JRFOutOfMemoryEventHandler)handler
                                 crashDetector:(JRFCrashDetector)crashDetector {

    [[self sharedInstance] beginApplicationMonitoring];
    signal(SIGABRT, JRFIntentionalQuitHandler);
    signal(SIGQUIT, JRFIntentionalQuitHandler);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Set up the static path for intentional aborts
    if ([JRFPathUtilities intentionalQuitPathname]) {
        intentionalQuitPathname = strdup([JRFPathUtilities intentionalQuitPathname]);
    }

    JRFCrashDetector detector = crashDetector;
    if (!detector) {
        [self setupDefaultCrashReporting];
        detector = [self defaultCrashDetector];
    }

    BOOL didIntentionallyQuit = NO;
    struct stat statbuffer;
    if (stat(intentionalQuitPathname, &statbuffer) == 0){
        // A file exists at the path, we had an intentional quit
        didIntentionallyQuit = YES;
    }
    BOOL didCrash = detector();
    BOOL didTerminate = [defaults boolForKey:JRFAppWasTerminatedKey];
    BOOL didUpgradeApp = ![[self currentBundleVersion] isEqualToString:[self previousBundleVersion]];
    BOOL didUpgradeOS = ![[self currentOSVersion] isEqualToString:[self previousOSVersion]];
    if (!(didIntentionallyQuit || didCrash || didTerminate || didUpgradeApp || didUpgradeOS)) {
        if (handler) {
            BOOL wasInBackground = [[NSUserDefaults standardUserDefaults] boolForKey:JRFAppWasInBackgroundKey];
            handler(!wasInBackground);
        }
    }

    [defaults setObject:[self currentBundleVersion] forKey:JRFPreviousBundleVersionKey];
    [defaults setObject:[self currentOSVersion] forKey:JRFPreviousOSVersionKey];
    [defaults setBool:NO forKey:JRFAppWasTerminatedKey];
    [defaults setBool:NO forKey:JRFAppWasInBackgroundKey];
    [defaults setBool:NO forKey:JRFAppDidCrashKey];
    [defaults synchronize];
    // Remove intentional quit file
    unlink(intentionalQuitPathname);
}

#pragma mark termination and backgrounding

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (void)beginApplicationMonitoring {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:JRFAppWasTerminatedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:JRFAppWasInBackgroundKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:JRFAppWasInBackgroundKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark app version

+ (NSString *)currentBundleVersion {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *majorVersion = infoDictionary[@"CFBundleShortVersionString"];
    NSString *minorVersion = infoDictionary[@"CFBundleVersion"];
    return [NSString stringWithFormat:@"%@.%@", majorVersion, minorVersion];
}

+ (NSString *)previousBundleVersion {
    return [[NSUserDefaults standardUserDefaults] objectForKey:JRFPreviousBundleVersionKey];
}

#pragma mark OS version

+ (NSString *)stringFromOperatingSystemVersion:(NSOperatingSystemVersion)version {
    return [NSString stringWithFormat:@"%@.%@.%@", @(version.majorVersion), @(version.minorVersion), @(version.patchVersion)];
}

+ (NSString *)currentOSVersion {
    return [self stringFromOperatingSystemVersion:[[NSProcessInfo processInfo] operatingSystemVersion]];
}

+ (NSString *)previousOSVersion {
    return [[NSUserDefaults standardUserDefaults] objectForKey:JRFPreviousOSVersionKey];
}

#pragma mark crash reporting

+ (void)setupDefaultCrashReporting {
    if (NSGetUncaughtExceptionHandler()) {
        NSLog(@"Warning: something in your application (probably a crash reporting framework) has already set an uncaught exception handler. This will break that code. You should pass a crashReporter block to checkForOutOfMemoryEventsWithHandler:crashReporter: that uses your crash reporting framework.");
    }
    
    NSSetUncaughtExceptionHandler(&defaultExceptionHandler);
}

static void defaultExceptionHandler (NSException *exception) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:JRFAppDidCrashKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static void JRFIntentionalQuitHandler(int signal) {
    creat(intentionalQuitPathname, S_IREAD | S_IWRITE);
}

+ (JRFCrashDetector)defaultCrashDetector {
    return ^() {
        return [[NSUserDefaults standardUserDefaults] boolForKey:JRFAppDidCrashKey];
    };
}

@end
