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
#import "IIViewDeckController.h"
#import "TransparentToolbar.h"
#import "OCAPIClient.h"
#import "OCNewsHelper.h"
#import <QuartzCore/QuartzCore.h>
#import "HexColor.h"
#import "UIImage+Resource.h"

#define MIN_FONT_SIZE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 11 : 9)
#define MAX_FONT_SIZE 30

#define MIN_LINE_HEIGHT 1.2f
#define MAX_LINE_HEIGHT 2.6f

#define MIN_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 380 : 150)
#define MAX_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 700 : 300)

@interface OCWebController () <UIPopoverControllerDelegate, IIViewDeckControllerDelegate> {
    UIPopoverController *_activityPopover;
    PopoverView *_popover;
    BOOL _menuIsOpen;
}

@property (strong, nonatomic, readonly) UIPopoverController *prefPopoverController;
@property (strong, nonatomic, readonly) PHPrefViewController *prefViewController;

- (void)configureView;
- (void) writeAndLoadHtml:(NSString*)html;
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
@synthesize background;

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
    if (_item != newItem) {
        _item = newItem;
        if (!_item.extra) {
            [[OCNewsHelper sharedHelper] addItemExtra:_item];
        }
        // Update the view.
        [self configureView];
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
            [self.view insertSubview:self.webView atIndex:0];
            [self.webView addSubview:self.menuController.view];

        } else {
            NSLog(@"Now here");
            __block UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
            imageView.frame = self.view.frame;
            imageView.image = [self screenshot];
            [self.view insertSubview:imageView atIndex:0];
            
            [self.view setNeedsDisplay];
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
                            }];
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
        Feed *feed = [[OCNewsHelper sharedHelper] feedWithId:self.item.feedIdValue];
        
        if (feed.extra.preferWebValue) {
            if (feed.extra.useReaderValue) {
                if (self.item.extra.readable) {
                    [self writeAndLoadHtml:self.item.extra.readable];
                } else {
                    [[OCAPIClient sharedClient] getPath:self.item.url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        NSString *html;
                        NSLog(@"Response: %@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
                        if (responseObject) {
                            html = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                            char *article;
                            article = readable([html cStringUsingEncoding:NSUTF8StringEncoding],
                                               [[[operation.response URL] absoluteString] cStringUsingEncoding:NSUTF8StringEncoding],
                                               "UTF-8",
                                               READABLE_OPTIONS_DEFAULT);
                            if (article == NULL) {
                                html = @"<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>";
                                html = [html stringByAppendingString:self.item.body];
                            } else {
                                html = [NSString stringWithCString:article encoding:NSUTF8StringEncoding];
                                html = [self fixRelativeUrl:html
                                              baseUrlString:[NSString stringWithFormat:@"%@://%@/%@", [[operation.response URL] scheme], [[operation.response URL] host], [[operation.response URL] path]]];
                            }
                            self.item.extra.readable = html;
                            [[OCNewsHelper sharedHelper] saveContext];
                        } else {
                            html = @"<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>";
                            html = [html stringByAppendingString:self.item.body];
                        }
                        [self writeAndLoadHtml:html];

                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"Error: %@", error);
                        NSString *html;
                        html = @"<p style='color: #CC6600;'><i>(There was an error downloading the article. Showing summary instead.)</i></p>";
                        html = [html stringByAppendingString:self.item.body];
                        [self writeAndLoadHtml:html];

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
    
    Feed *feed = [[OCNewsHelper sharedHelper] feedWithId:self.item.feedIdValue];
    objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$FeedTitle$" withString:feed.extra.displayTitle];
    objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleDate$" withString:dateText];
    objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleTitle$" withString:self.item.title];
    objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleLink$" withString:self.item.url];
    NSString *author = self.item.author;
    if (![author isKindOfClass:[NSNull class]]) {
        if (author.length > 0) {
            author = [NSString stringWithFormat:@"By %@", author];
        }
    } else {
        author = @"";
    }
    objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleAuthor$" withString:author];
    objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleSummary$" withString:html];
    
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
    if (_popover) {
        [_popover dismiss:NO];
    }
    //[_gmController close];
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
    FDReadabilityActivity *ra = [[FDReadabilityActivity alloc] init];
    
    NSArray *activityItems = @[url];
    NSArray *activities = @[sa, ia, ipa, ra];
    
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
        [self.background setColumns:nil];
        [self.background setIsModal:NO];
        [self.background setHideOnExpand:NO];
        self.background.isMoreButton = YES;
        [self.background.button setImage:[UIImage imageNamed:@"down"] forState:UIControlStateNormal];
        [[self.menuController.rows objectAtIndex:2 + 1] button].hidden = YES;
        [[self.menuController.rows objectAtIndex:2 + 2] button].hidden = YES;
        [[self.menuController.rows objectAtIndex:2 + 3] button].hidden = YES;
    } else {
        //self.keepUnread.button.selected = self.item.unreadValue;
        NSLog(@"Starred Value: %d", self.item.starredValue);
        
        [self.menuController open];
        [self.star.button setSelected:self.item.starredValue];
    }
    _menuIsOpen = !_menuIsOpen;
   
    /*
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.prefPopoverController presentPopoverFromBarButtonItem:self.textBarButtonItem permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown) animated:YES];
    } else {
        CGPoint popoverPoint;
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            // Load resources for iOS 6.1 or earlier
            UIView *tbar = (UIView*)self.navigationItem.rightBarButtonItem.customView;
            popoverPoint = CGPointMake(tbar.frame.origin.x + 70, tbar.frame.origin.y);
        } else {
            CGPoint touchPoint = [[event.allTouches anyObject] locationInView:self.viewDeckController.view];
            CGRect rect = self.viewDeckController.view.frame;
            popoverPoint = CGPointMake(touchPoint.x, touchPoint.y + rect.origin.y);
        }
        _popover = [[PopoverView alloc] initWithFrame:self.prefViewController.view.frame];
        [_popover showAtPoint:popoverPoint inView:self.view withContentView:self.prefViewController.view] ;
    }*/
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
                    //[[rowSelected button] setSelected:YES];
                    [[rowSelected button] setSelected:![rowSelected button].selected];
                    break;
                case 1: // Star
                    //[[rowSelected button] setSelected:YES];
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
                    
                    [self.background setColumns:[NSMutableArray arrayWithArray:@[backgroundWhite, backgroundSepia]]];
                    [self.background setIsMoreButton:NO];
                    [self.background setIsModal:YES];
                    [self.background.button setImage:[UIImage imageNamed:@"background1"] forState:UIControlStateNormal];
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
        backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageResourceNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(doGoBack:)];
        backBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    
    if (!forwardBarButtonItem) {
        forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageResourceNamed:@"forward"] style:UIBarButtonItemStylePlain target:self action:@selector(doGoForward:)];
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
        textBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageResourceNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(doText:event:)];
        textBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return textBarButtonItem;
}

- (UIBarButtonItem *)starBarButtonItem {
    if (!starBarButtonItem) {
        starBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageResourceNamed:@"star_open"] style:UIBarButtonItemStylePlain target:self action:@selector(doStar:)];
        starBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return starBarButtonItem;
}

- (UIBarButtonItem *)unstarBarButtonItem {
    if (!unstarBarButtonItem) {
        unstarBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageResourceNamed:@"star_filled"] style:UIBarButtonItemStylePlain target:self action:@selector(doStar:)];
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

- (JCGridMenuRow *)background {
    if (!background) {
        background = [[JCGridMenuRow alloc] initWithImages:@"down" selected:@"close_blue" highlighted:@"background1" disabled:@"background1"];
        [background setColumns:nil];
        [background setIsModal:NO];
        [background setHideOnExpand:NO];
        [background.button setBackgroundColor:[UIColor colorWithWhite:0.97f alpha:0.95f]];
        background.isMoreButton = YES;
    }
    return background;
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
        NSArray *rows = @[self.keepUnread, self.star, self.background, font, spacing, margin];
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
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 5.0f;

    NSArray *itemsLeft = [NSArray arrayWithObjects:
                      fixedSpace,
                      self.backBarButtonItem,
                      fixedSpace,
                      self.forwardBarButtonItem,
                      fixedSpace,
                      refreshStopBarButtonItem,
                      fixedSpace,
                      nil];

    TransparentToolbar *toolbarLeft = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 125.0f, 44.0f)];
    toolbarLeft.items = itemsLeft;
    toolbarLeft.tintColor = self.navigationController.navigationBar.tintColor;
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbarLeft];
    } else {
        // Load resources for iOS 7 or later
        self.navigationItem.leftBarButtonItems = @[self.backBarButtonItem, self.forwardBarButtonItem, refreshStopBarButtonItem];
    }


    //UIBarButtonItem *starUnstarBarButtonItem = ([self.item.starred isEqual:[NSNumber numberWithInt:1]]) ? self.unstarBarButtonItem : self.starBarButtonItem;
    self.star.button.selected = self.item.starredValue;
    refreshStopBarButtonItem.enabled = (self.item != nil);

    NSArray *itemsRight = @[fixedSpace, self.actionBarButtonItem, fixedSpace, self.textBarButtonItem];
    
    TransparentToolbar *toolbarRight = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0, 44.0f)];
    toolbarRight.items = itemsRight;
    toolbarRight.tintColor = self.navigationController.navigationBar.tintColor;
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbarRight];
    } else {
        // Load resources for iOS 7 or later
        self.navigationItem.rightBarButtonItems = @[self.textBarButtonItem, self.actionBarButtonItem];
    }

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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LeftTapZone" object:self userInfo:nil];
        }
        if ([gesture isEqual:self.nextArticleRecognizer]) {
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
    //CGRect rect = CGRectMake(0, 0, 320, 480);
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    UIImage *capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return capturedScreen;
}

- (void)popoverViewDidDismiss:(PopoverView *)popoverView {
    _popover = nil;
}

- (void)viewDeckController:(IIViewDeckController *)viewDeckController applyShadow:(CALayer *)shadowLayer withBounds:(CGRect)rect {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
    } else {
        shadowLayer.masksToBounds = NO;
        shadowLayer.shadowRadius = 2;
        shadowLayer.shadowOpacity = 0.9;
        shadowLayer.shadowColor = [[UIColor blackColor] CGColor];
        shadowLayer.shadowOffset = CGSizeZero;
        shadowLayer.shadowPath = [[UIBezierPath bezierPathWithRect:rect] CGPath];
    }
}

@end
