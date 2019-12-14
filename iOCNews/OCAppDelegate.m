//
//  OCAppDelegate.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2013 Peter Hedlund peter.hedlund@me.com
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 *************************************************************************/

#import "OCAppDelegate.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import "OCNewsHelper.h"
#import <KSCrash/KSCrash.h>
#import <KSCrash/KSCrashInstallationEmail.h>
#import <KSCrash/KSCrashInstallation+Alert.h>
#import "PDKeychainBindings.h"
#import "PHThemeManager.h"
@import UserNotifications;

@implementation OCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    KSCrashInstallation* installation = [self makeEmailInstallation];
    [installation install];
    
    UISplitViewController *svc = (UISplitViewController *)self.window.rootViewController;
    svc.maximumPrimaryColumnWidth = svc.primaryColumnWidth;
    if (@available(iOS 13, *)) {
        svc.presentsWithGesture = NO;
    } else {
        svc.presentsWithGesture = YES;
    }
    UINavigationController *navController = (UINavigationController *)svc.viewControllers.lastObject;
    navController.topViewController.navigationItem.leftBarButtonItem = svc.displayModeButtonItem;

    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"]]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SyncInBackground"]) {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    } else {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }

    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[PDKeychainBindings sharedKeychainBindings] setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)(kSecAttrAccessible)];

    [self writeCss];
    
    [installation sendAllReportsWithCompletion:^(NSArray* reports, BOOL completed, NSError* error) {
        if(completed) {
//            NSLog(@"Sent %d reports", (int)[reports count]);
        } else{
//            NSLog(@"Failed to send reports: %@", error);
        }
    }];
    
    [PHThemeManager sharedManager];
    return YES;
}

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [[OCNewsHelper sharedHelper] sync:completionHandler];
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionBadge completionHandler:^(BOOL granted, NSError * _Nullable error) {
        //
    }];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (KSCrashInstallation*) makeEmailInstallation {
    NSString* emailAddress = @"support@pbh.dev";
    
    KSCrashInstallationEmail* email = [KSCrashInstallationEmail sharedInstance];
    email.recipients = @[emailAddress];
    email.subject = @"CloudNews Crash Report";
    email.message = @"<Please provide as much details as possible about what you were doing when the crash occurred.>";
    email.filenameFmt = @"crash-report-%d.txt.gz";
    
    [email addConditionalAlertWithTitle:@"Crash Detected"
                                message:@"CloudNews crashed last time it was launched. Do you want to send a report to the developer?"
                              yesAnswer:@"Yes, please!"
                               noAnswer:@"No thanks"];
    
    // Uncomment to send Apple style reports instead of JSON.
    [email setReportStyle:KSCrashEmailReportStyleApple useDefaultFilenameFormat:YES];
    
    return email;
}

- (void) writeCss {
    NSBundle *appBundle = [NSBundle mainBundle];
    NSURL *cssTemplateURL = [appBundle URLForResource:@"rss" withExtension:@"css" subdirectory:nil];
    NSString *cssTemplate = [NSString stringWithContentsOfURL:cssTemplateURL encoding:NSUTF8StringEncoding error:nil];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    [cssTemplate writeToURL:[docDir URLByAppendingPathComponent:@"rss.css"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
