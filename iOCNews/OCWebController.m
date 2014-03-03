//
//  WebController.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2012-2013 Peter Hedlund peter.hedlund@me.com
 
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

#import "OCWebController.h"
#import "readable.h"
#import "HTMLParser.h"
#import "TUSafariActivity.h"
#import "FDReadabilityActivity.h"
#import "FDiCabActivity.h"
#import "FDInstapaperActivity.h"
#import "OCPocketActivity.h"
#import "IIViewDeckController.h"
#import "OCAPIClient.h"
#import "OCNewsHelper.h"
#import <QuartzCore/QuartzCore.h>
#import "HexColor.h"

#define MIN_FONT_SIZE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 11 : 9)
#define MAX_FONT_SIZE 30

#define MIN_LINE_HEIGHT 1.2f
#define MAX_LINE_HEIGHT 2.6f

#define MIN_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 380 : 150)
#define MAX_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 700 : 300)

const int SWIPE_NEXT = 0;
const int SWIPE_PREVIOUS = 1;

@interface OCWebController () <UIPopoverControllerDelegate, IIViewDeckControllerDelegate> {
    UIPopoverController *_activityPopover;
    BOOL _menuIsOpen;
    int _swipeDirection;
}

@property (strong, nonatomic, readonly) UIPopoverController *prefPopoverController;
@property (strong, nonatomic, readonly) PHPrefViewController *prefViewController;

- (void)configureView;
- (void) writeAndLoadHtml:(NSString*)html;
- (NSString *)replaceYTIframe:(NSString *)html;
- (NSString *)extractYoutubeVideoID:(NSString *)urlYoutube;
- (UIColor*)myBackgroundColor;

@end

@implementation OCWebController

@synthesize backBarButtonItem, forwardBarButtonItem, refreshBarButtonItem, stopBarButtonItem, actionBarButtonItem, textBarButtonItem, starBarButtonItem, unstarBarButtonItem;
@synthesize nextArticleRecognizer;
@synthesize previousArticleRecognizer;
@synthesize prefPopoverController;
@synthesize prefViewController;
@synthesize item = _item;
@synthesize menuController;
@synthesize keepUnread;
@synthesize star;
@synthesize backgroundMenuRow;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Managing the detail item

- (void)setItem:(Item*)newItem
{
    Item *myItem = (Item*)[[OCNewsHelper sharedHelper].context objectWithID:newItem.objectID];
    if (myItem) {
        if (_item != myItem) {
            _item = myItem;
            // Update the view.
            [self configureView];
        }
    }
}

- (void)configureView
{
    if (self.item) {
        if ([self.viewDeckController isAnySideOpen]) {
            if (self.webView != nil) {
                [self.menuController.view removeFromSuperview];
                [self.webView removeFromSuperview];
                self.webView.delegate =nil;
                self.webView = nil;
            }

            CGFloat topBarOffset = self.topLayoutGuide.length;
            CGRect frame = self.view.frame;
            self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(frame.origin.x, topBarOffset, frame.size.width, frame.size.height - topBarOffset)];
            self.automaticallyAdjustsScrollViewInsets = NO;

            self.webView.scalesPageToFit = YES;
            self.webView.delegate = self;
            self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.webView.scrollView.directionalLockEnabled = YES;
            [self.view insertSubview:self.webView atIndex:0];
            [self.webView addSubview:self.menuController.view];

        } else {
            __block UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
            imageView.frame = self.view.frame;
            imageView.image = [self screenshot];
            [self.view insertSubview:imageView atIndex:0];
            
            [self.view setNeedsDisplay];
            
            float width = self.view.frame.size.width;
            float height = self.view.frame.size.height;
            
            if (self.webView != nil) {
                [self.menuController.view removeFromSuperview];
                [self.webView removeFromSuperview];
                self.webView.delegate =nil;
                self.webView = nil;
            }
            __block CGFloat topBarOffset = self.topLayoutGuide.length;

            self.automaticallyAdjustsScrollViewInsets = NO;
 
            if (_swipeDirection == SWIPE_NEXT) {
                self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(width, topBarOffset, width, height - topBarOffset)];
            } else {
                self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(-width, topBarOffset, width, height - topBarOffset)];
            }
            self.webView.scalesPageToFit = YES;
            self.webView.delegate = self;
            self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.webView.scrollView.directionalLockEnabled = YES;
            [self.webView addSubview:self.menuController.view];
            [self.view insertSubview:self.webView belowSubview:imageView];

            [UIView animateWithDuration:0.3f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 [self.webView setFrame:CGRectMake(0.0, topBarOffset, width, height - topBarOffset)];
                                 if (_swipeDirection == SWIPE_NEXT) {
                                     [imageView setFrame:CGRectMake(-width, 0.0, width, height)];
                                 } else {
                                     [imageView setFrame:CGRectMake(width, 0.0, width, height)];
                                 }
                             }
                             completion:^(BOOL finished){
                                 // do whatever post processing you want (such as resetting what is "current" and what is "next")
                                 [imageView removeFromSuperview];
                                 [self.view.layer displayIfNeeded];
                                 imageView = nil;
                             }];
            
            /* old fade animation
            [UIView transitionWithView:self.view
                              duration:0.3
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                
                                if (self.webView != nil) {
                                    [self.menuController.view removeFromSuperview];
                                    [self.webView removeFromSuperview];
                                    self.webView.delegate =nil;
                                    self.webView = nil;
                                }
                                if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                                    // Load resources for iOS 6.1 or earlier
                                    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
                                } else {
                                    // Load resources for iOS 7 or later
                                    CGFloat topBarOffset = self.topLayoutGuide.length;
                                    CGRect frame = self.view.frame;
                                    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(frame.origin.x, topBarOffset, frame.size.width, frame.size.height - topBarOffset)];
                                    self.automaticallyAdjustsScrollViewInsets = NO;
                                }
                                self.webView.scalesPageToFit = YES;
                                self.webView.delegate = self;
                                self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                                self.webView.scrollView.directionalLockEnabled = YES;
                                [self.webView addSubview:self.menuController.view];
                                [self.view insertSubview:self.webView belowSubview:imageView];
                                [imageView removeFromSuperview];
                                [self.view.layer displayIfNeeded];
                            }
                            completion:^(BOOL finished) {
                                if (finished) {
                                    imageView = nil;
                                }
                            }];*/
        }
        
        [self.webView addGestureRecognizer:self.nextArticleRecognizer];
        [self.webView addGestureRecognizer:self.previousArticleRecognizer];

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                self.navigationItem.title = self.item.title;
            } else {
                self.navigationItem.title = @"";
            }
        } else {
            self.navigationItem.title = self.item.title;
        }
        Feed *feed = [[OCNewsHelper sharedHelper] feedWithId:self.item.feedId];
        
        if (feed.preferWebValue) {
            if (feed.useReaderValue) {
                if (self.item.readable) {
                    [self writeAndLoadHtml:self.item.readable];
                } else {
                    [[OCAPIClient sharedClient] setResponseSerializer:[AFHTTPResponseSerializer serializer]];

                    [[OCAPIClient sharedClient] GET:self.item.url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                        NSString *html;
                        NSLog(@"Response: %@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
                        if (responseObject) {
                            html = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                            char *article;
                            article = readable([html cStringUsingEncoding:NSUTF8StringEncoding],
                                               [[[task.response URL] absoluteString] cStringUsingEncoding:NSUTF8StringEncoding],
                                               "UTF-8",
                                               READABLE_OPTIONS_DEFAULT);
                            if (article == NULL) {
                                html = @"<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>";
                                html = [html stringByAppendingString:self.item.body];
                            } else {
                                html = [NSString stringWithCString:article encoding:NSUTF8StringEncoding];
                                html = [self fixRelativeUrl:html
                                              baseUrlString:[NSString stringWithFormat:@"%@://%@/%@", [[task.response URL] scheme], [[task.response URL] host], [[task.response URL] path]]];
                            }
                            self.item.readable = html;
                            [[OCNewsHelper sharedHelper] saveContext];
                        } else {
                            html = @"<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>";
                            html = [html stringByAppendingString:self.item.body];
                        }
                        //restore the response serializer
                        [[OCAPIClient sharedClient] setResponseSerializer:[AFJSONResponseSerializer serializer]];
                        [self writeAndLoadHtml:html];

                    } failure:^(NSURLSessionDataTask *task, NSError *error) {
                        NSLog(@"Error: %@", error);
                        NSString *html;
                        html = @"<p style='color: #CC6600;'><i>(There was an error downloading the article. Showing summary instead.)</i></p>";
                        html = [html stringByAppendingString:self.item.body];
                        [self writeAndLoadHtml:html];
                        //restore the response serializer
                        [[OCAPIClient sharedClient] setResponseSerializer:[AFJSONResponseSerializer serializer]];
                    }];
                }
            } else {
                [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.item.url]]];
            }
        } else {
            NSString *html = self.item.body;
            NSURL *itemURL = [NSURL URLWithString:self.item.url];
            NSString *baseString = [NSString stringWithFormat:@"%@://%@", [itemURL scheme], [itemURL host]];
            html = [self fixRelativeUrl:html baseUrlString:baseString];
            [self writeAndLoadHtml:html];
        }
        if ([self.viewDeckController isAnySideOpen]) {
        
        [self.viewDeckController closeLeftView];
        }
        [self updateToolbar];
    }
}

- (void)writeAndLoadHtml:(NSString *)html {
    html = [self replaceYTIframe:html];
    NSURL *source = [[NSBundle mainBundle] URLForResource:@"rss" withExtension:@"html" subdirectory:nil];
    NSString *objectHtml = [NSString stringWithContentsOfURL:source encoding:NSUTF8StringEncoding error:nil];
    
    NSString *dateText = @"";
    NSNumber *dateNumber = self.item.pubDate;
    if (![dateNumber isKindOfClass:[NSNull class]]) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dateNumber doubleValue]];
        if (date) {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            dateFormat.dateStyle = NSDateFormatterMediumStyle;
            dateFormat.timeStyle = NSDateFormatterShortStyle;
            dateText = [dateText stringByAppendingString:[dateFormat stringFromDate:date]];
        }
    }
    
    Feed *feed = [[OCNewsHelper sharedHelper] feedWithId:self.item.feedId];
    if (feed && feed.title) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$FeedTitle$" withString:feed.title];
    }
    if (dateText) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleDate$" withString:dateText];
    }
    if (self.item.title) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleTitle$" withString:self.item.title];
    }
    if (self.item.url) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleLink$" withString:self.item.url];
    }
    NSString *author = self.item.author;
    if (![author isKindOfClass:[NSNull class]]) {
        if (author.length > 0) {
            author = [NSString stringWithFormat:@"By %@", author];
        }
    } else {
        author = @"";
    }
    if (author) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleAuthor$" withString:author];
    }
    if (html) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleSummary$" withString:html];
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    NSURL *objectSaveURL = [docDir  URLByAppendingPathComponent:@"summary.html"];
    [objectHtml writeToURL:objectSaveURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:objectSaveURL]];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"]]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _menuIsOpen = NO;
    [self writeCss];
    [self updateToolbar];
    self.viewDeckController.panningGestureDelegate = self;
    self.viewDeckController.delegate = self;
    self.viewDeckController.view.backgroundColor = [self myBackgroundColor];
    [self.viewDeckController toggleLeftView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)dealloc
{
    [self.webView stopLoading];
 	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.webView.delegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            if (self.item != nil) {
                self.navigationItem.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
            }
        } else {
            self.navigationItem.title = @"";
        }
    }
}
- (IBAction)doGoBack:(id)sender
{
    if ([[self webView] canGoBack]) {
        [[self webView] goBack];
    }
}

- (IBAction)doGoForward:(id)sender
{
    if ([[self webView] canGoForward]) {
        [[self webView] goForward];
    }
}


- (IBAction)doReload:(id)sender {
    [self.webView reload];
}

- (IBAction)doStop:(id)sender {
    [self.webView stopLoading];
	[self updateToolbar];
}

- (IBAction)doInfo:(id)sender {
    NSURL *url = self.webView.request.URL;
    if ([[url absoluteString] hasSuffix:@"Documents/summary.html"]) {
        url = [NSURL URLWithString:self.item.url];
    }
    
    TUSafariActivity *sa = [[TUSafariActivity alloc] init];
    FDiCabActivity *ia = [[FDiCabActivity alloc] init];
    FDInstapaperActivity *ipa = [[FDInstapaperActivity alloc] init];
    OCPocketActivity *pa = [[OCPocketActivity alloc] init];
    FDReadabilityActivity *ra = [[FDReadabilityActivity alloc] init];
    
    NSArray *activityItems = @[url];
    NSArray *activities = @[sa, ia, ipa, pa, ra];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:activities];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {

    if (![_activityPopover isPopoverVisible]) {
        _activityPopover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
		_activityPopover.delegate = self;
		[_activityPopover presentPopoverFromBarButtonItem:self.actionBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
    } else {
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	_activityPopover = nil;
}

- (IBAction)doText:(id)sender event:(UIEvent*)event {
    if (_menuIsOpen) {
        [self.menuController close];
        [self.backgroundMenuRow setColumns:nil];
        [self.backgroundMenuRow setIsModal:NO];
        [self.backgroundMenuRow setHideOnExpand:NO];
        self.backgroundMenuRow.isMoreButton = YES;
        [self.backgroundMenuRow.button setImage:[UIImage imageNamed:@"down"] forState:UIControlStateNormal];
        [[self.menuController.rows objectAtIndex:2 + 1] button].hidden = YES;
        [[self.menuController.rows objectAtIndex:2 + 2] button].hidden = YES;
        [[self.menuController.rows objectAtIndex:2 + 3] button].hidden = YES;
    } else {
        self.keepUnread.button.selected = self.item.unreadValue;
        self.star.button.selected = self.item.starredValue;
        [self.menuController open];
    }
    _menuIsOpen = !_menuIsOpen;
}

- (IBAction)doStar:(id)sender {
    if ([sender isEqual:self.starBarButtonItem]) {
        self.item.starredValue = YES;
        [[OCNewsHelper sharedHelper] starItemOffline:self.item.myId];
    }
    if ([sender isEqual:self.unstarBarButtonItem]) {
        self.item.starredValue = NO;
        [[OCNewsHelper sharedHelper] unstarItemOffline:self.item.myId];
    }
    [self updateToolbar];
}

#pragma mark - UIWebView delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([self.webView.request.URL.scheme isEqualToString:@"file"]) {
        if ([request.URL.absoluteString rangeOfString:@"itunes.apple.com"].location != NSNotFound) {
            [[UIApplication sharedApplication] openURL:request.URL];
            return NO;
        }
    }
    if (![[request.URL absoluteString] hasSuffix:@"Documents/summary.html"]) {
        [self.menuController close];
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateToolbar];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) ||
            ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)) {
                self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        } else {
            self.navigationItem.title = @"";
        }
    } else {
        self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    }
    [self updateToolbar];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateToolbar];
}


#pragma mark - JCGridMenuController Delegate

- (void)jcGridMenuRowSelected:(NSInteger)indexTag indexRow:(NSInteger)indexRow isExpand:(BOOL)isExpand
{
    if (isExpand) {
        NSLog(@"jcGridMenuRowSelected %i %i isExpand", indexTag, indexRow);
    } else {
        NSLog(@"jcGridMenuRowSelected %i %i !isExpand", indexTag, indexRow);
    }
    
    if (indexTag==1002) {
        JCGridMenuRow *rowSelected = (JCGridMenuRow *)[self.menuController.rows objectAtIndex:indexRow];
        
        if ([rowSelected.columns count]==0) {
            // If there are no more columns, we can use this button as an on/off switch
            
            switch (indexRow) {
                case 0: // Keep unread
                    if (!self.item.unreadValue) {
                        self.item.unreadValue = YES;
                        [[OCNewsHelper sharedHelper] markItemUnreadOffline:self.item.myId];
                        [[rowSelected button] setSelected:YES];
                    } else {
                        self.item.unreadValue = NO;
                        [[OCNewsHelper sharedHelper] markItemsReadOffline:@[self.item.myId]];
                        [[rowSelected button] setSelected:NO];
                    }
                    break;
                case 1: // Star
                    if (!self.item.starredValue) {
                        self.item.starredValue = YES;
                        [[OCNewsHelper sharedHelper] starItemOffline:self.item.myId];
                        [[rowSelected button] setSelected:YES];
                    } else {
                        self.item.starredValue = NO;
                        [[OCNewsHelper sharedHelper] unstarItemOffline:self.item.myId];
                        [[rowSelected button] setSelected:NO];
                    }
                    break;
                case 2: // Expand
                    [[rowSelected button] setSelected:NO];
                    break;
            }

        } else {
            //This changes the icon to Close
            [[[[self.menuController rows] objectAtIndex:indexRow] button] setSelected:isExpand];
        }
    }
    
}

- (void)jcDidSelectGridMenuRow:(NSInteger)tag indexRow:(NSInteger)indexRow isExpand:(BOOL)isExpand {
    if (tag==1002) {
        JCGridMenuRow *rowSelected = (JCGridMenuRow *)[self.menuController.rows objectAtIndex:indexRow];
        
        if ([rowSelected.columns count]==0) {
            // If there are no more columns, we can use this button as an on/off switch
            //[[rowSelected button] setSelected:![rowSelected button].selected];
            switch (indexRow) {
                case 0: // Keep unread
                    //[[rowSelected button] setSelected:YES];
                    break;
                case 1: // Star
                    //[[rowSelected button] setSelected:YES];
                    break;
                case 2: // Expand
                    [[self.menuController.rows objectAtIndex:indexRow + 1] button].hidden = NO;
                    [[self.menuController.rows objectAtIndex:indexRow + 2] button].hidden = NO;
                    [[self.menuController.rows objectAtIndex:indexRow + 3] button].hidden = NO;
                    
                    // Background
                    JCGridMenuColumn *backgroundWhite = [[JCGridMenuColumn alloc]
                                                         initWithButtonAndImages:CGRectMake(0, 0, 44, 44)
                                                         normal:@"background1"
                                                         selected:@"background1"
                                                         highlighted:@"background1"
                                                         disabled:@"background1"];
                    [backgroundWhite.button setBackgroundColor:[UIColor colorWithWhite:0.90f alpha:0.95f]];
                    backgroundWhite.closeOnSelect = NO;
                    
                    JCGridMenuColumn *backgroundSepia = [[JCGridMenuColumn alloc]
                                                         initWithButtonAndImages:CGRectMake(0, 0, 44, 44)
                                                         normal:@"background2"
                                                         selected:@"background2"
                                                         highlighted:@"background2"
                                                         disabled:@"background2"];
                    [backgroundSepia.button setBackgroundColor:[UIColor colorWithWhite:0.90f alpha:0.95f]];
                    backgroundSepia.closeOnSelect = NO;
                    
                    [self.backgroundMenuRow setColumns:[NSMutableArray arrayWithArray:@[backgroundWhite, backgroundSepia]]];
                    [self.backgroundMenuRow setIsMoreButton:NO];
                    [self.backgroundMenuRow setIsModal:YES];
                    [self.backgroundMenuRow.button setImage:[UIImage imageNamed:@"background1"] forState:UIControlStateNormal];
                    break;
            }
            
        }
    }
}

- (void)jcGridMenuColumnSelected:(NSInteger)indexTag indexRow:(NSInteger)indexRow indexColumn:(NSInteger)indexColumn
{
    NSLog(@"jcGridMenuColumnSelected %i %i %i", indexTag, indexRow, indexColumn);
    
    if (indexTag==1002) {
        [self.menuController setIsRowModal:YES];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        int currentValue;
        double currentLineSpacing;
        switch (indexRow) {
            case 0: // Keep
                //Will not happen
                break;
            case 1: // Star
                //Will not happen
                break;
            case 2: //Background
                switch (indexColumn) {
                    case 0: // White
                        [prefs setInteger:0 forKey:@"Background"];
                        break;
                    case 1: // Sepia
                        [prefs setInteger:1 forKey:@"Background"];
                        break;
                }
                break;
            case 3: //Font size
                switch (indexColumn) {
                    case 0: // Smaller
                        currentValue = [[prefs valueForKey:@"FontSize"] integerValue];
                        if (currentValue > MIN_FONT_SIZE) {
                            --currentValue;
                        }
                        [prefs setInteger:currentValue forKey:@"FontSize"];
                        break;
                    case 1: // Larger
                        currentValue = [[prefs valueForKey:@"FontSize"] integerValue];
                        if (currentValue < MAX_FONT_SIZE) {
                            ++currentValue;
                        }
                        [prefs setInteger:currentValue forKey:@"FontSize"];
                        break;
                }
                break;
            case 4: //Line spacing
                switch (indexColumn) {
                    case 0: // Smaller
                        currentLineSpacing = [[prefs valueForKey:@"LineHeight"] doubleValue];
                        if (currentLineSpacing > MIN_LINE_HEIGHT) {
                            currentLineSpacing = currentLineSpacing - 0.2f;
                        }
                        [prefs setDouble:currentLineSpacing forKey:@"LineHeight"];
                        break;
                    case 1: // Larger
                        currentLineSpacing = [[prefs valueForKey:@"LineHeight"] doubleValue];
                        if (currentLineSpacing < MAX_LINE_HEIGHT) {
                            currentLineSpacing = currentLineSpacing + 0.2f;
                        }
                        [prefs setDouble:currentLineSpacing forKey:@"LineHeight"];
                        break;
                }
                break;
            case 5: //Margin
                switch (indexColumn) {
                    case 0: // Narrower
                        currentValue = [[prefs valueForKey:@"Margin"] integerValue];
                        if (currentValue < MAX_WIDTH) {
                            currentValue = currentValue + 20;
                        }
                        [prefs setInteger:currentValue forKey:@"Margin"];
                        break;
                    case 1: // Wider
                        currentValue = [[prefs valueForKey:@"Margin"] integerValue];
                        
                        if (currentValue > MIN_WIDTH) {
                            currentValue = currentValue - 20;
                        }
                        [prefs setInteger:currentValue forKey:@"Margin"];
                        break;
                }
                break;
        }
        [self settingsChanged:Nil newValue:0];
    }
}


#pragma mark - Toolbar buttons

- (UIBarButtonItem *)backBarButtonItem {
    
    if (!backBarButtonItem) {
        backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(doGoBack:)];
        backBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    
    if (!forwardBarButtonItem) {
        forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward"] style:UIBarButtonItemStylePlain target:self action:@selector(doGoForward:)];
        forwardBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    
    if (!refreshBarButtonItem) {
        refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(doReload:)];
    }
    
    return refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    
    if (!stopBarButtonItem) {
        stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(doStop:)];
    }
    return stopBarButtonItem;
}

- (UIBarButtonItem *)actionBarButtonItem {
    if (!actionBarButtonItem) {
        actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(doInfo:)];
    }
    return actionBarButtonItem;
}

- (UIBarButtonItem *)textBarButtonItem {
    
    if (!textBarButtonItem) {
        textBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(doText:event:)];
        textBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return textBarButtonItem;
}

- (UIBarButtonItem *)starBarButtonItem {
    if (!starBarButtonItem) {
        starBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"star_open"] style:UIBarButtonItemStylePlain target:self action:@selector(doStar:)];
        starBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return starBarButtonItem;
}

- (UIBarButtonItem *)unstarBarButtonItem {
    if (!unstarBarButtonItem) {
        unstarBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"star_filled"] style:UIBarButtonItemStylePlain target:self action:@selector(doStar:)];
        unstarBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return unstarBarButtonItem;
}

- (JCGridMenuRow *)keepUnread {
    if (!keepUnread) {
        // Keep Unread
        keepUnread = [[JCGridMenuRow alloc] initWithImages:@"keep_blue" selected:@"keep_green" highlighted:@"keep_green" disabled:@"keep_blue"];
        [keepUnread setHideAlpha:1.0f];
        [keepUnread setIsModal:NO];
        [keepUnread.button setBackgroundColor:[UIColor colorWithWhite:0.97f alpha:0.95f]];
    }
    return keepUnread;
}

- (JCGridMenuRow *)star {
    if (!star) {
        // Star
        star = [[JCGridMenuRow alloc] initWithImages:@"star_blue_open" selected:@"star_blue_filled" highlighted:@"star_blue_filled" disabled:@"star_blue_open"];
        [star setIsSeperated:NO];
        [star setIsSelected:NO];
        [star setHideAlpha:1.0f];
        [star setIsModal:NO];
        [star.button setBackgroundColor:[UIColor colorWithWhite:0.97f alpha:0.95f]];
    }
    return star;
}

- (JCGridMenuRow *)backgroundMenuRow {
    if (!backgroundMenuRow) {
        backgroundMenuRow = [[JCGridMenuRow alloc] initWithImages:@"down" selected:@"close_blue" highlighted:@"background1" disabled:@"background1"];
        [backgroundMenuRow setColumns:nil];
        [backgroundMenuRow setIsModal:NO];
        [backgroundMenuRow setHideOnExpand:NO];
        [backgroundMenuRow.button setBackgroundColor:[UIColor colorWithWhite:0.97f alpha:0.95f]];
        backgroundMenuRow.isMoreButton = YES;
    }
    return backgroundMenuRow;
}

- (JCGridMenuController *)menuController {
    if (!menuController) {
        // Background
        // Handled above
        
        // Font
        JCGridMenuColumn *fontSmaller = [[JCGridMenuColumn alloc]
                                         initWithButtonAndImages:CGRectMake(0, 0, 44, 44)
                                         normal:@"fontsizes"
                                         selected:@"fontsizes"
                                         highlighted:@"fontsizes"
                                         disabled:@"fontsizes"];
        [fontSmaller.button setBackgroundColor:[UIColor colorWithWhite:0.90f alpha:0.95f]];
        fontSmaller.closeOnSelect = NO;
        
        JCGridMenuColumn *fontLarger = [[JCGridMenuColumn alloc]
                                        initWithButtonAndImages:CGRectMake(0, 0, 44, 44)
                                        normal:@"fontsizel"
                                        selected:@"fontsizel"
                                        highlighted:@"fontsizel"
                                        disabled:@"fontsizel"];
        [fontLarger.button setBackgroundColor:[UIColor colorWithWhite:0.90f alpha:0.95f]];
        fontLarger.closeOnSelect = NO;
        
        JCGridMenuRow *font = [[JCGridMenuRow alloc] initWithImages:@"fontsizem" selected:@"close_blue" highlighted:@"fontsizem" disabled:@"fontsizem"];
        [font setColumns:[NSMutableArray arrayWithArray:@[fontSmaller, fontLarger]]];
        [font setIsModal:YES];
        [font setHideOnExpand:NO];
        [font.button setBackgroundColor:[UIColor colorWithWhite:0.97f alpha:0.95f]];
        font.button.hidden = YES;
        // Line Spacing
        JCGridMenuColumn *spacingSmaller = [[JCGridMenuColumn alloc]
                                            initWithButtonAndImages:CGRectMake(0, 0, 44, 44)
                                            normal:@"lineheight1"
                                            selected:@"lineheight1"
                                            highlighted:@"lineheight1"
                                            disabled:@"lineheight1"];
        [spacingSmaller.button setBackgroundColor:[UIColor colorWithWhite:0.90f alpha:0.95f]];
        spacingSmaller.closeOnSelect = NO;
        
        JCGridMenuColumn *spacingLarger = [[JCGridMenuColumn alloc]
                                           initWithButtonAndImages:CGRectMake(0, 0, 44, 44)
                                           normal:@"lineheight3"
                                           selected:@"lineheight3"
                                           highlighted:@"lineheight3"
                                           disabled:@"lineheight3"];
        [spacingLarger.button setBackgroundColor:[UIColor colorWithWhite:0.90f alpha:0.95f]];
        spacingLarger.closeOnSelect = NO;
        
        JCGridMenuRow *spacing = [[JCGridMenuRow alloc] initWithImages:@"lineheight2" selected:@"close_blue" highlighted:@"lineheight2" disabled:@"lineheight2"];
        [spacing setColumns:[NSMutableArray arrayWithArray:@[spacingSmaller, spacingLarger]]];
        [spacing setIsModal:YES];
        [spacing setHideOnExpand:NO];
        [spacing.button setBackgroundColor:[UIColor colorWithWhite:0.97f alpha:0.95f]];
        spacing.button.hidden = YES;
        // Margin
        JCGridMenuColumn *marginSmaller = [[JCGridMenuColumn alloc]
                                           initWithButtonAndImages:CGRectMake(0, 0, 44, 44)
                                           normal:@"margin1"
                                           selected:@"margin1"
                                           highlighted:@"margin1"
                                           disabled:@"margin1"];
        [marginSmaller.button setBackgroundColor:[UIColor colorWithWhite:0.90f alpha:0.95f]];
        marginSmaller.closeOnSelect = NO;
        
        JCGridMenuColumn *marginLarger = [[JCGridMenuColumn alloc]
                                          initWithButtonAndImages:CGRectMake(0, 0, 44, 44)
                                          normal:@"margin3"
                                          selected:@"margin3"
                                          highlighted:@"margin3"
                                          disabled:@"margin3"];
        [marginLarger.button setBackgroundColor:[UIColor colorWithWhite:0.90f alpha:0.95f]];
        marginLarger.closeOnSelect = NO;
        
        JCGridMenuRow *margin = [[JCGridMenuRow alloc] initWithImages:@"margin2" selected:@"close_blue" highlighted:@"margin2" disabled:@"margin2"];
        [margin setColumns:[NSMutableArray arrayWithArray:@[marginSmaller, marginLarger]]];
        [margin setIsModal:YES];
        [margin setHideOnExpand:NO];
        [margin.button setBackgroundColor:[UIColor colorWithWhite:0.97f alpha:0.95f]];
        margin.button.hidden = YES;
        // Rows
        NSArray *rows = @[self.keepUnread, self.star, self.backgroundMenuRow, font, spacing, margin];
        menuController = [[JCGridMenuController alloc] initWithFrame:CGRectMake(0, 5, self.view.frame.size.width - 5, self.view.frame.size.height - 5) rows:rows tag:1002];
        [menuController setDelegate:self];
    }
    return menuController;
}

#pragma mark - Toolbar

- (void)updateToolbar {
    self.backBarButtonItem.enabled = self.webView.canGoBack;
    self.forwardBarButtonItem.enabled = self.webView.canGoForward;
    if ((self.item != nil)) {
        self.actionBarButtonItem.enabled = !self.webView.isLoading;
        self.textBarButtonItem.enabled = !self.webView.isLoading;
        self.starBarButtonItem.enabled = !self.webView.isLoading;
        self.unstarBarButtonItem.enabled = !self.webView.isLoading;
    } else {
        self.actionBarButtonItem.enabled = NO;
        self.textBarButtonItem.enabled = NO;
        self.starBarButtonItem.enabled = NO;
        self.unstarBarButtonItem.enabled = NO;
    }

    UIBarButtonItem *refreshStopBarButtonItem = self.webView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    refreshStopBarButtonItem.enabled = (self.item != nil);
    self.navigationItem.leftBarButtonItems = @[self.backBarButtonItem, self.forwardBarButtonItem, refreshStopBarButtonItem];

    self.keepUnread.button.selected = self.item.unreadValue;
    self.star.button.selected = self.item.starredValue;
    self.navigationItem.rightBarButtonItems = @[self.textBarButtonItem, self.actionBarButtonItem];
}

- (NSString *) fixRelativeUrl:(NSString *)htmlString baseUrlString:(NSString*)base {
    __block NSString *result = [htmlString copy];
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:htmlString error:&error];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return result;
    }

    //parse body
    HTMLNode *bodyNode = [parser body];

    NSArray *inputNodes = [bodyNode findChildTags:@"img"];
    [inputNodes enumerateObjectsUsingBlock:^(HTMLNode *inputNode, NSUInteger idx, BOOL *stop) {
        if (inputNode) {
            NSString *src = [inputNode getAttributeNamed:@"src"];
            if (src != nil) {
                NSURL *url = [NSURL URLWithString:src relativeToURL:[NSURL URLWithString:base]];
                if (url != nil) {
                    NSString *newSrc = [url absoluteString];
                    result = [result stringByReplacingOccurrencesOfString:src withString:newSrc];
                }
            }
        }
    }];
    
    inputNodes = [bodyNode findChildTags:@"a"];
    [inputNodes enumerateObjectsUsingBlock:^(HTMLNode *inputNode, NSUInteger idx, BOOL *stop) {
        if (inputNode) {
            NSString *src = [inputNode getAttributeNamed:@"href"];
            if (src != nil) {
                NSURL *url = [NSURL URLWithString:src relativeToURL:[NSURL URLWithString:base]];
                if (url != nil) {
                    NSString *newSrc = [url absoluteString];
                    result = [result stringByReplacingOccurrencesOfString:src withString:newSrc];
                }
                
            }
        }
    }];
    
    return result;
}

#pragma mark - Tap zones

- (UISwipeGestureRecognizer *)nextArticleRecognizer {
    if (!nextArticleRecognizer) {
        nextArticleRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        nextArticleRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        nextArticleRecognizer.delegate = self;
    }
    return nextArticleRecognizer;
}

- (UISwipeGestureRecognizer *)previousArticleRecognizer {
    if (!previousArticleRecognizer) {
        previousArticleRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        previousArticleRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        previousArticleRecognizer.delegate = self;
    }
    return previousArticleRecognizer;
}
/*
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    //NSURL *url = self.webView.request.URL;
    //if ([[url absoluteString] hasSuffix:@"Documents/summary.html"]) {
        
        CGPoint loc = [touch locationInView:self.webView];
        
        //See http://www.icab.de/blog/2010/07/11/customize-the-contextual-menu-of-uiwebview/
        // Load the JavaScript code from the Resources and inject it into the web page
        NSString *path = [[NSBundle mainBundle] pathForResource:@"script" ofType:@"js"];
        NSString *jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        [self.webView stringByEvaluatingJavaScriptFromString: jsCode];
        
        // get the Tags at the touch location
        NSString *tags = [self.webView stringByEvaluatingJavaScriptFromString:
                          [NSString stringWithFormat:@"FDGetHTMLElementsAtPoint(%i,%i);",(NSInteger)loc.x,(NSInteger)loc.y]];
        
        // If a link was touched, eat the touch
        return ([tags rangeOfString:@",A,"].location == NSNotFound);
    //} else {
    //    return false;
    //}
}
*/
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    //[_gmController close];
    CGPoint loc = [gestureRecognizer locationInView:self.webView];
    float h = self.webView.frame.size.height;
    float q = h / 4;
    if ([gestureRecognizer isEqual:self.nextArticleRecognizer]) {
        return YES;
    }
    if ([gestureRecognizer isEqual:self.previousArticleRecognizer]) {
        if (loc.y > q) {
            if (loc.y < (h - q)) {
                return ![self.viewDeckController isAnySideOpen];
            }
        }
        return NO;
    }
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        if (loc.y < q) {
            return YES;
        }
        if (loc.y > (3 * q)) {
            return YES;
        }
        return NO;
    }
    return NO;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if ([gesture isEqual:self.previousArticleRecognizer]) {
            _swipeDirection = SWIPE_PREVIOUS;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LeftTapZone" object:self userInfo:nil];
        }
        if ([gesture isEqual:self.nextArticleRecognizer]) {
            _swipeDirection = SWIPE_NEXT;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RightTapZone" object:self userInfo:nil];
        }
    }
}

- (void)viewDeckController:(IIViewDeckController*)viewDeckController willOpenViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
    if (self.webView) {
        [self.webView removeGestureRecognizer:self.nextArticleRecognizer];
        [self.webView removeGestureRecognizer:self.previousArticleRecognizer];
    }
}

- (void)viewDeckController:(IIViewDeckController *)viewDeckController didOpenViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
    if (self.webView) {
        self.webView.scrollView.scrollsToTop = NO;
    }
}

- (void)viewDeckController:(IIViewDeckController*)viewDeckController willCloseViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
    if (self.webView) {
        [self.webView addGestureRecognizer:self.nextArticleRecognizer];
        [self.webView addGestureRecognizer:self.previousArticleRecognizer];
    }
}

#pragma mark - Reader settings

- (void) writeCss
{
    NSBundle *appBundle = [NSBundle mainBundle];
    NSURL *cssTemplateURL = [appBundle URLForResource:@"rss" withExtension:@"css" subdirectory:nil];
    NSString *cssTemplate = [NSString stringWithContentsOfURL:cssTemplateURL encoding:NSUTF8StringEncoding error:nil];
    
    int fontSize =[[NSUserDefaults standardUserDefaults] integerForKey:@"FontSize"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$FONTSIZE$" withString:[NSString stringWithFormat:@"%dpx", fontSize]];
    
    int margin =[[NSUserDefaults standardUserDefaults] integerForKey:@"Margin"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$MARGIN$" withString:[NSString stringWithFormat:@"%dpx", margin]];
    
    double lineHeight =[[NSUserDefaults standardUserDefaults] doubleForKey:@"LineHeight"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$LINEHEIGHT$" withString:[NSString stringWithFormat:@"%fem", lineHeight]];
    
    NSArray *backgrounds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Backgrounds"];
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    NSString *background = [backgrounds objectAtIndex:backgroundIndex];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$BACKGROUND$" withString:background];
    
    NSArray *colors = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Colors"];
    NSString *color = [colors objectAtIndex:backgroundIndex];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLOR$" withString:color];
    
    NSArray *colorsLink = [[NSUserDefaults standardUserDefaults] arrayForKey:@"ColorsLink"];
    NSString *colorLink = [colorsLink objectAtIndex:backgroundIndex];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$COLORLINK$" withString:colorLink];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    
    [cssTemplate writeToURL:[docDir URLByAppendingPathComponent:@"rss.css"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (UIColor*)myBackgroundColor {
    NSArray *backgrounds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Backgrounds"];
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    NSString *background = [backgrounds objectAtIndex:backgroundIndex];
    UIColor *backColor = [UIColor colorWithHexString:background];
    return backColor;
}

- (PHPrefViewController*)prefViewController {
    if (!prefViewController) {
        UIStoryboard *storyboard;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
        } else {
            storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        }
        prefViewController = [storyboard instantiateViewControllerWithIdentifier:@"preferences"];
        prefViewController.delegate = self;
    }
    return prefViewController;
}

- (UIPopoverController*)prefPopoverController {
    if (!prefPopoverController) {
        prefPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.prefViewController];
        prefPopoverController.popoverContentSize = CGSizeMake(240.0f, 260.0f);
    }
    return prefPopoverController;
}

-(void) settingsChanged:(NSString *)setting newValue:(NSUInteger)value {
    //NSLog(@"New Setting: %@ with value %d", setting, value);
    [self writeCss];
    self.viewDeckController.view.backgroundColor = [self myBackgroundColor];
    if ([self webView] != nil) {
        [self.webView reload];
    }
}

- (UIImage*)screenshot {
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    UIImage *capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return capturedScreen;
}

- (void)viewDeckController:(IIViewDeckController *)viewDeckController applyShadow:(CALayer *)shadowLayer withBounds:(CGRect)rect {
    shadowLayer.masksToBounds = NO;
    shadowLayer.shadowRadius = 1;
    shadowLayer.shadowOpacity = 0.9;
    shadowLayer.shadowColor = [[UIColor blackColor] CGColor];
    shadowLayer.shadowOffset = CGSizeZero;
    shadowLayer.shadowPath = [[UIBezierPath bezierPathWithRect:rect] CGPath];
}

- (NSString*)replaceYTIframe:(NSString *)html {
    __block NSString *result = html;
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&error];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return html;
    }
    
    //parse body
    HTMLNode *bodyNode = [parser body];
    
    NSArray *inputNodes = [bodyNode findChildTags:@"iframe"];
    [inputNodes enumerateObjectsUsingBlock:^(HTMLNode *inputNode, NSUInteger idx, BOOL *stop) {
        if (inputNode) {
            NSString *src = [inputNode getAttributeNamed:@"src"];
            if (src && [src rangeOfString:@"youtu"].location != NSNotFound) {
                NSString *videoID = [self extractYoutubeVideoID:src];
                if (videoID) {
                    NSLog(@"Raw: %@", [inputNode rawContents]);
                    
                    NSString *height = [inputNode getAttributeNamed:@"height"];
                    NSString *width = [inputNode getAttributeNamed:@"width"];
                    NSString *heightString = @"";
                    NSString *widthString = @"";
                    if (height.length > 0) {
                        heightString = [NSString stringWithFormat:@"height=\"%@\"", height];
                    }
                    if (width.length > 0) {
                        widthString = [NSString stringWithFormat:@"width=\"%@\"", width];
                    }
                    NSString *embed = [NSString stringWithFormat:@"<embed id=\"yt\" src=\"http://www.youtube.com/v/%@\" type=\"application/x-shockwave-flash\" %@ %@></embed>", videoID, heightString, widthString];
                    result = [result stringByReplacingOccurrencesOfString:[inputNode rawContents] withString:embed];
                }
            }
        }
    }];
    
    return result;
}


//based on https://gist.github.com/rais38/4683817
/**
 @see https://devforums.apple.com/message/705665#705665
 extractYoutubeVideoID: works for the following URL formats:
 www.youtube.com/v/VIDEOID
 www.youtube.com?v=VIDEOID
 www.youtube.com/watch?v=WHsHKzYOV2E&feature=youtu.be
 www.youtube.com/watch?v=WHsHKzYOV2E
 youtu.be/KFPtWedl7wg_U923
 www.youtube.com/watch?feature=player_detailpage&v=WHsHKzYOV2E#t=31s
 youtube.googleapis.com/v/WHsHKzYOV2E
 www.youtube.com/embed/VIDEOID
 */

- (NSString *)extractYoutubeVideoID:(NSString *)urlYoutube {
    NSString *regexString = @"(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)|(?<=embed/)([-a-zA-Z0-9_]+)";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:urlYoutube options:0 range:NSMakeRange(0, [urlYoutube length])];
    if(!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
        NSString *substringForFirstMatch = [urlYoutube substringWithRange:rangeOfFirstMatch];
        return substringForFirstMatch;
    }
    
    return nil;
}

@end
