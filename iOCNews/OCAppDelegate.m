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
#import "IIViewDeckController.h"
#import "OCNewsHelper.h"
#import "UAAppReviewManager.h"

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
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    }
    
    UIViewController *feedController = [storyboard instantiateViewControllerWithIdentifier:@"feed"];
    UIViewController *articleController = [storyboard instantiateViewControllerWithIdentifier:@"article"];
    UIViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"web"];
    
    IIViewDeckController* secondDeckController = [[IIViewDeckController alloc] initWithCenterViewController:articleController
                                                                                          leftViewController:feedController];

    secondDeckController.panningCancelsTouchesInView = YES;
    secondDeckController.parallaxAmount = 0.2f;

    IIViewDeckController* deckController = [[IIViewDeckController alloc] initWithCenterViewController:webController
                                                                                   leftViewController:secondDeckController];
    deckController.sizeMode = IIViewDeckLedgeSizeMode;
    secondDeckController.sizeMode = IIViewDeckViewSizeMode;
    deckController.leftSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 40 : 10;
    deckController.parallaxAmount = 0.2f;
    
    self.window.rootViewController = deckController;
    [self.window makeKeyAndVisible];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SyncInBackground"]) {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    } else {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }
    [UAAppReviewManager showPromptIfNecessary];
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
