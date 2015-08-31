`JRFMemoryNoodler`
===

What is this?
---

Facebook put out a neat [engineering blog post](https://code.facebook.com/posts/1146930688654547/reducing-fooms-in-the-facebook-ios-app/) last week about trying to detect when their app is killed by iOS due to memory pressure (the OS doesn't give your app any feedback this is happening). It's a neat post, go read it if you haven't or this won't make any sense.

Anyway, the short of is is that instead of trying to detect when their app is being killed, they try and figure out why the application needs to start up (as, after the first-ever run of the app, this implies that it was killed at some point in the past). The reasons they came up with were:

1. The user upgraded their version of the app (or is installing it for the first time).
2. The app itself called `abort()` or `quit()` in code (weird, and hopefully rare, but technically valid)
3. The app crashed.
4. The user force-quit the app by swiping up on it in the task switcher or restarting their device.
5. The user upgraded their iOS version.
6. The app was killed by the OS for using too much memory (this is the case we're trying to detect)

So, since there's no way to detect #6 directly, one can instead try and rule out #'s 1-5 instead. If none of 1-5 is true, then 6 is true, and the application was killed for using too much memory.

Anyway, they didn't include any code for this, so I took a crack at it.

---

`JRFMemoryNoodler` exposes exactly 1 class method:
```objc
+ (void)beginMonitoringMemoryEventsWithHandler:(JRFOutOfMemoryEventHandler)handler
                                 crashDetector:(JRFCrashDetector)crashDetector;
```
You should call this method as early as possible in your application's lifecycle, ideally during `application:didFinishLaunchingWithOptions:`. You give it 2 blocks: `handler` is a bit of code to be executed when `JRFMemoryNoodler` figures out that your app was previously out-of-memoried (it also includes a `BOOL` that will tell you if the app was in the foreground or not at the time). So, at this point, you could post an event to your server or something.

`crashDetector` is a little funnier. So, the way most crash reporting frameworks work is by using a method called `NSSetUncaughtExceptionHandler`, which takes a pointer to a function that iOS will call when your app has triggered an uncaught exception and is about to crash (most crash reporters will then try and figure out what has gone wrong and write it to disk so they can log it to a server or something later). Unfortunately, this can only point to a single function, so if `JRFMemoryNoodler` were to use it to figure out if the app is recovering from a crash, it would break any crash reporting frameworks. Since if you are interested in this memory profiling, you are almost certainly using a crash reporting framework, this would be a Bad Thing. So, the `crashDetector` param is a block that lets you ask your crash reporting framework if it has any crashes to report. You can leave it `nil`, in which case `JRFMemoryNoodler` will set up a very very simple crash reporter of its own, but you probably don't want this.\

Putting it all together looks something like this:
```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [JRFMemoryNoodler beginMonitoringMemoryEventsWithHandler:^(BOOL wasInForeground) {
        [MySweetAnalyticsService recordEvent:APP_KILLED_DUE_TO_MEMORY_PRESSURE wasInForeground:wasInForeground];
    } crashDetector:^BOOL{
        return [MySweetCrashReportingFramework appDidCrashOnLastRun];
    }];
    return YES;
}
```

---

Should you use this?
---

Sure! That being said, I'm guessing ~every crash reporting framework is going to start doing this out of the box, so maybe make sure that you're not duplicating any functionality. Also, I mostly just did this as an experiment, so I'm probably not going to maintain it too much (PRs and such are of course welcome though). If you decide to use this in your app, or think it's cool or whatever, drop me a line @jflinter.

Thanks for reading!

Oh right how to install this
===

The app exposes a Cocoa Touch framework target, so you can either drag the project into your app directly or install it via [Carthage](https://github.com/Carthage/Carthage). Or, I mean, it's just a single `.h` and `.m` that you can just toss into your app too.