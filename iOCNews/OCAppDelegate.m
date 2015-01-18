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
#import "AFNetworkActivityIndicatorManager.h"
#import "OCNewsHelper.h"
#import "UAAppReviewManager.h"
#import <KSCrash/KSCrash.h>
#import <KSCrash/KSCrashInstallationEmail.h>
#import "PocketAPI.h"
#import "PocketCredentials.h"
#import "FDTopDrawerController.h"
#import "FDBottomDrawerController.h"

@implementation OCAppDelegate

+ (void)initialize {
	[OCAppDelegate setupUAAppReviewManager];
}

+ (void)setupUAAppReviewManager {
	// Normally, all the setup would be here.
	// But, because we are presenting a few different setups in the example,
	// The config will be in the view controllers
	[UAAppReviewManager setAppID:@"683859706"]; // iOCNews
    [UAAppReviewManager setDaysUntilPrompt:14];
    [UAAppReviewManager setShouldPromptIfRated:NO];
	//
	// It is always best to load UAAppReviewManager as early as possible
	// because it needs to receive application life-cycle notifications,
	// so we will call a simple method on it here to load it up now.
	[UAAppReviewManager setDebug:NO];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    KSCrashInstallation* installation = [self makeEmailInstallation];
    [installation install];
	[[PocketAPI sharedAPI] setConsumerKey:CONSUMER_KEY];

//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    }
    
    [UINavigationBar appearance].barTintColor = [UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1.0];
    [UINavigationBar appearance].tintColor = [UIColor colorWithRed:0.13 green:0.145 blue:0.16 alpha:1.0];

    [[UIView appearanceWhenContainedIn:[UIAlertController class], nil] setTintColor:[UINavigationBar appearance].tintColor];
    
//    UINavigationController *feedController = [storyboard instantiateViewControllerWithIdentifier:@"feed"];
//    UINavigationController *articleController = [storyboard instantiateViewControllerWithIdentifier:@"article"];
//    UINavigationController *webController = [storyboard instantiateViewControllerWithIdentifier:@"web"];
//
//    FDBottomDrawerController *bottomDrawerController = [[FDBottomDrawerController alloc] initWithCenterViewController:articleController leftDrawerViewController:feedController];
//    [bottomDrawerController willRotateToInterfaceOrientation:application.statusBarOrientation duration:0];
//    bottomDrawerController.feedListController = (OCFeedListController*)feedController.topViewController;
//    bottomDrawerController.articleListController = (OCArticleListController*)articleController.topViewController;
//    
//    FDTopDrawerController *topDrawerController = [[FDTopDrawerController alloc] initWithCenterViewController:webController leftDrawerViewController:bottomDrawerController];
//    [topDrawerController willRotateToInterfaceOrientation:application.statusBarOrientation duration:0];
//    topDrawerController.webController = (OCWebController*)webController.topViewController;
//    
//    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
//    self.window.rootViewController = topDrawerController;
//    [self.window makeKeyAndVisible];
//    
//    self.window.frame = [UIScreen mainScreen].bounds;
//
//    [bottomDrawerController willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
//    [topDrawerController willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];

    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SyncInBackground"]) {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    } else {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }
    [UAAppReviewManager showPromptIfNecessary];

    [installation sendAllReportsWithCompletion:^(NSArray* reports, BOOL completed, NSError* error) {
        if(completed) {
            NSLog(@"Sent %d reports", (int)[reports count]);
        } else{
            NSLog(@"Failed to send reports: %@", error);
        }
    }];
    
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	if([[PocketAPI sharedAPI] handleOpenURL:url]) {
		return YES;
	} else {
		// if you handle your own URLs, do it here
		return NO;
	}
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (KSCrashInstallation*) makeEmailInstallation {
    NSString* emailAddress = @"support@peterandlinda.com";
    
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



@end
