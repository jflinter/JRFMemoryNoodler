//
//  JRFMemoryNoodler.h
//  JRFMemoryNoodler
//
//  Created by Jack Flintermann on 8/30/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

@import Foundation;

@interface JRFMemoryNoodler : NSObject

/**
 *  A block to be called when JRFMemoryNoodler decides your app was killed due to memory pressure.
 *
 *  @param wasInForeground whether or not the app was in the foreground when this happened.
 */
typedef void (^JRFOutOfMemoryEventHandler)(BOOL wasInForeground);

/**
 *  A function that returns whether or not the application is recovering from a crash. (If so, JRFMemoryNoodler won't report that the app was killed due to memory pressure). If you're using a crash reporting framework like HockeyApp, it almost definitionally has a method to figure this out that you should use. For example, with HockeyApp you could just `return [[BITHockeyManager sharedHockeyManager] didCrashInLastSession]` here.
 *
 *  @return whether or not the application is recovered from a crash.
 */
typedef BOOL (^JRFCrashDetector)();

/**
 *  You should call this method as early as possible in your application's lifecycle, ideally during `application:didFinishLaunchingWithOptions:`
 *
 *  @param handler       A bit of code to be executed when `JRFMemoryNoodler` figures out that your app was previously out-of-memoried. So, at this point, you could post an event to your server or something.
 
 *  @param crashDetector So, the way most crash reporting frameworks work is by using a method called `NSSetUncaughtExceptionHandler`, which takes a pointer to a function that iOS will call when your app has triggered an uncaught exception and is about to crash (most crash reporters will then try and figure out what has gone wrong and write it to disk so they can log it to a server or something later). Unfortunately, this can only point to a single function, so if `JRFMemoryNoodler` were to use it to figure out if the app is recovering from a crash, it would break any crash reporting frameworks. Since if you are interested in this memory profiling, you are almost certainly using a crash reporting framework, this would be a Bad Thing. So, the `crashDetector` param is a block that lets you ask your crash reporting framework if it has any crashes to report. You can leave it `nil`, in which case `JRFMemoryNoodler` will set up a very very simple crash reporter of its own, but you probably don't want this.
 */
+ (void)beginMonitoringMemoryEventsWithHandler:(nonnull JRFOutOfMemoryEventHandler)handler
                                 crashDetector:(nullable JRFCrashDetector)crashDetector;

@end
