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
#import "OCAPIClient.h"
#import "OCNewsHelper.h"
#import <QuartzCore/QuartzCore.h>
#import "OCSharingProvider.h"
#import "PHPrefViewController.h"
#import "UIColor+PHColor.h"

#define MIN_FONT_SIZE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 11 : 9)
#define MAX_FONT_SIZE 30

#define MIN_LINE_HEIGHT 1.2f
#define MAX_LINE_HEIGHT 2.6f

#define MIN_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 380 : 150)
#define MAX_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 700 : 300)

const int SWIPE_NEXT = 0;
const int SWIPE_PREVIOUS = 1;

@interface OCWebController () <WKNavigationDelegate, WKUIDelegate, PHPrefViewControllerDelegate, UIPopoverPresentationControllerDelegate> {
    BOOL _menuIsOpen;
    int _swipeDirection;
    BOOL loadingComplete;
    BOOL loadingSummary;
}

@property (strong, nonatomic) IBOutlet WKWebView *webView;
@property (assign, nonatomic) BOOL isVisible;
@property (nonatomic, strong, readonly) PHPrefViewController *settingsViewController;
@property (nonatomic, strong, readonly) UIPopoverPresentationController *settingsPresentationController;

- (void)configureView;
- (void) writeAndLoadHtml:(NSString*)html;
- (NSString *)replaceYTIframe:(NSString *)html;
- (NSString *)extractYoutubeVideoID:(NSString *)urlYoutube;
- (UIColor*)myBackgroundColor;

@end

@implementation OCWebController

@synthesize menuBarButtonItem;
@synthesize backBarButtonItem, forwardBarButtonItem, refreshBarButtonItem, stopBarButtonItem, actionBarButtonItem, textBarButtonItem, starBarButtonItem, unstarBarButtonItem;
@synthesize item = _item;
@synthesize menuController;
@synthesize keepUnread;
@synthesize star;
@synthesize backgroundMenuRow;
@synthesize settingsViewController;
@synthesize settingsPresentationController;

#pragma mark - Managing the detail item

- (void)configureView
{
    @try {
        if (self.item) {
            self.automaticallyAdjustsScrollViewInsets = NO;
            
            [self.webView addSubview:self.menuController.view];
            [self updateNavigationItemTitle];
            
            Feed *feed = [[OCNewsHelper sharedHelper] feedWithId:self.item.feedId];
            
            if (feed.preferWebValue) {
                if (feed.useReaderValue) {
                    if (self.item.readable) {
                        [self writeAndLoadHtml:self.item.readable];
                    } else {
                        [OCAPIClient sharedClient].requestSerializer = [OCAPIClient httpRequestSerializer];
                        [[OCAPIClient sharedClient] GET:self.item.url parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                            NSString *html;
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
                            [self writeAndLoadHtml:html];
                            
                        } failure:^(NSURLSessionDataTask *task, NSError *error) {
                            NSString *html = @"<p style='color: #CC6600;'><i>(There was an error downloading the article. Showing summary instead.)</i></p>";
                            if (self.item.body != nil) {
                                html = [html stringByAppendingString:self.item.body];
                            }
                            [self writeAndLoadHtml:html];
                        }];
                    }
                } else {
                    loadingSummary = NO;
                    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.item.url]]];
                }
            } else {
                NSString *html = self.item.body;
                NSURL *itemURL = [NSURL URLWithString:self.item.url];
                NSString *baseString = [NSString stringWithFormat:@"%@://%@", [itemURL scheme], [itemURL host]];
                html = [self fixRelativeUrl:html baseUrlString:baseString];
                [self writeAndLoadHtml:html];
            }
        }
        
    }
    @catch (NSException *exception) {
        //
    }
    @finally {
        //
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
    loadingComplete = NO;
    loadingSummary = YES;
    [self.webView loadFileURL:objectSaveURL allowingReadAccessToURL:docDir];
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    WKWebViewConfiguration *webConfig = [WKWebViewConfiguration new];
    
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webConfig];
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [_webView addSubview:self.menuController.view];
    self.view = _webView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isVisible = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"]]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _menuIsOpen = NO;
    [self writeCss];
    [self configureView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.isVisible = YES;
    [self updateToolbar];
    [self updateNavigationItemTitle];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.isVisible = NO;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)dealloc
{
    [self.webView stopLoading];
 	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    self.webView.navigationDelegate = nil;
    self.webView.UIDelegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)onMenu:(id)sender {
//    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
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
    @try {
        NSURL *url = self.webView.URL;
        NSString *subject = self.webView.title;
        if ([[url absoluteString] hasSuffix:@"Documents/summary.html"]) {
            url = [NSURL URLWithString:self.item.url];
            subject = self.item.title;
        }
        if (!url) {
            return;
        }
        
        TUSafariActivity *sa = [[TUSafariActivity alloc] init];
        NSArray *activities = @[sa];
        
        OCSharingProvider *sharingProvider = [[OCSharingProvider alloc] initWithPlaceholderItem:url subject:subject];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[sharingProvider] applicationActivities:activities];
        activityViewController.modalPresentationStyle = UIModalPresentationPopover;
        [self presentViewController:activityViewController animated:YES completion:nil];
        // Get the popover presentation controller and configure it.
        UIPopoverPresentationController *presentationController = [activityViewController popoverPresentationController];
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        presentationController.barButtonItem = self.actionBarButtonItem;
    }
    @catch (NSException *exception) {
        //
    }
    @finally {
        //
    }
}

- (IBAction)doPreferences:(id)sender {
    settingsPresentationController = self.settingsViewController.popoverPresentationController;
    settingsPresentationController.delegate = self;
    settingsPresentationController.barButtonItem = self.textBarButtonItem;
    settingsPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    settingsPresentationController.backgroundColor = [UIColor popoverBackgroundColor];
    [self presentViewController:self.settingsViewController animated:YES completion:nil];
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

#pragma mark - WKWbView delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([self.webView.URL.scheme isEqualToString:@"file"] || [self.webView.URL.scheme hasPrefix:@"itms"]) {
        if ([navigationAction.request.URL.absoluteString rangeOfString:@"itunes.apple.com"].location != NSNotFound) {
            [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }

    if (![[navigationAction.request.URL absoluteString] hasSuffix:@"Documents/summary.html"]) {
        [self.menuController close];
    }
    
    if (navigationAction.navigationType != WKNavigationTypeOther) {
        loadingSummary = [navigationAction.request.URL.scheme isEqualToString:@"file"] || [navigationAction.request.URL.scheme isEqualToString:@"about"];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
    loadingComplete = NO;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateToolbar];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateToolbar];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateToolbar];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(NSString * _Nullable response, NSError * _Nullable error) {
        if (response != nil) {
            if ([response isEqualToString:@"complete"]) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                loadingComplete = YES;
                [self updateNavigationItemTitle];
            }
        }
        [self updateToolbar];
    }];
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    
    return nil;
}

- (BOOL)isShowingASummary {
    BOOL result = NO;
    if (self.webView) {
        result = [self.webView.URL.scheme isEqualToString:@"file"] || [self.webView.URL.scheme isEqualToString:@"about"];
    }
    return result;
}

#pragma mark - JCGridMenuController Delegate

- (void)jcGridMenuRowSelected:(NSInteger)indexTag indexRow:(NSInteger)indexRow isExpand:(BOOL)isExpand
{
//    if (isExpand) {
//        NSLog(@"jcGridMenuRowSelected %li %li isExpand", (long)indexTag, (long)indexRow);
//    } else {
//        NSLog(@"jcGridMenuRowSelected %li %li !isExpand", (long)indexTag, (long)indexRow);
//    }
    
    if (indexTag==1002) {
        JCGridMenuRow *rowSelected = (JCGridMenuRow *)[self.menuController.rows objectAtIndex:indexRow];
        
        if ([rowSelected.columns count]==0) {
            // If there are no more columns, we can use this button as an on/off switch
            
            switch (indexRow) {
                case 0: // Keep unread
                    @try {
                        if (!self.item.unreadValue) {
                            self.item.unreadValue = YES;
                            [[OCNewsHelper sharedHelper] markItemUnreadOffline:self.item.myId];
                            [[rowSelected button] setSelected:YES];
                        } else {
                            self.item.unreadValue = NO;
                            [[OCNewsHelper sharedHelper] markItemsReadOffline:[NSMutableSet setWithObject:self.item.myId]];
                            [[rowSelected button] setSelected:NO];
                        }
                    }
                    @catch (NSException *exception) {
                        //
                    }
                    @finally {
                        break;
                    }
                case 1: // Star
                    @try {
                        if (!self.item.starredValue) {
                            self.item.starredValue = YES;
                            [[OCNewsHelper sharedHelper] starItemOffline:self.item.myId];
                            [[rowSelected button] setSelected:YES];
                        } else {
                            self.item.starredValue = NO;
                            [[OCNewsHelper sharedHelper] unstarItemOffline:self.item.myId];
                            [[rowSelected button] setSelected:NO];
                        }
                    }
                    @catch (NSException *exception) {
                        //
                    }
                    @finally {
                        break;
                    }
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
    if (indexTag==1002) {
        [self.menuController setIsRowModal:YES];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        long currentValue;
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

- (UIBarButtonItem *)menuBarButtonItem {
    if (!menuBarButtonItem) {
        menuBarButtonItem = [[UIBarButtonItem alloc] initWithImage:nil style:UIBarButtonItemStyleDone target:nil action:nil];
        menuBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return menuBarButtonItem;
}

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
        textBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(doPreferences:)];
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

- (PHPrefViewController *)settingsViewController {
    if (!settingsViewController) {
        settingsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"preferences"];
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//            settingsPageController.preferredContentSize = CGSizeMake(240, 362);
//        } else {
            settingsViewController.preferredContentSize = CGSizeMake(220, 305);
//        }
        settingsViewController.modalPresentationStyle = UIModalPresentationPopover;
        settingsViewController.delegate = self;
    }
    return settingsViewController;
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
    if (self.isVisible) {
        self.backBarButtonItem.enabled = self.webView.canGoBack;
        self.forwardBarButtonItem.enabled = self.webView.canGoForward;
        UIBarButtonItem *refreshStopBarButtonItem = loadingComplete ? self.refreshBarButtonItem : self.stopBarButtonItem;
        if ((self.item != nil)) {
            self.actionBarButtonItem.enabled = loadingComplete;
            self.textBarButtonItem.enabled = loadingComplete;
            self.starBarButtonItem.enabled = loadingComplete;
            self.unstarBarButtonItem.enabled = loadingComplete;
            refreshStopBarButtonItem.enabled = YES;
            self.keepUnread.button.selected = self.item.unreadValue;
            self.star.button.selected = self.item.starredValue;
        } else {
            self.actionBarButtonItem.enabled = NO;
            self.textBarButtonItem.enabled = NO;
            self.starBarButtonItem.enabled = NO;
            self.unstarBarButtonItem.enabled = NO;
            refreshStopBarButtonItem.enabled = NO;
        }
        self.parentViewController.parentViewController.navigationItem.leftBarButtonItems = @[self.menuBarButtonItem, self.backBarButtonItem, self.forwardBarButtonItem, refreshStopBarButtonItem];
        self.parentViewController.parentViewController.navigationItem.leftItemsSupplementBackButton = YES;
        self.parentViewController.parentViewController.navigationItem.rightBarButtonItems = @[self.textBarButtonItem, self.actionBarButtonItem];
    }
}

- (NSString *) fixRelativeUrl:(NSString *)htmlString baseUrlString:(NSString*)base {
    __block NSString *result = [htmlString copy];
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:htmlString error:&error];
    
    if (error) {
        //NSLog(@"Error: %@", error);
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

#pragma mark - Reader settings

- (void) writeCss
{
    NSBundle *appBundle = [NSBundle mainBundle];
    NSURL *cssTemplateURL = [appBundle URLForResource:@"rss" withExtension:@"css" subdirectory:nil];
    NSString *cssTemplate = [NSString stringWithContentsOfURL:cssTemplateURL encoding:NSUTF8StringEncoding error:nil];
    
    long fontSize =[[NSUserDefaults standardUserDefaults] integerForKey:@"FontSize"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$FONTSIZE$" withString:[NSString stringWithFormat:@"%ldpx", fontSize]];

    CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
    NSInteger margin =[[NSUserDefaults standardUserDefaults] integerForKey:@"MarginPortrait"];
    double currentWidth = (screenSize.width / [UIScreen mainScreen].scale) * ((double)margin / 100);
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$MARGIN$" withString:[NSString stringWithFormat:@"%ldpx", (long)currentWidth]];
    
    NSInteger marginLandscape = [[NSUserDefaults standardUserDefaults] integerForKey:@"MarginLandscape"];
    double currentWidthLandscape = (screenSize.height / [UIScreen mainScreen].scale) * ((double)marginLandscape / 100);
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$MARGIN_LANDSCAPE$" withString:[NSString stringWithFormat:@"%ldpx", (long)currentWidthLandscape]];

    double lineHeight =[[NSUserDefaults standardUserDefaults] doubleForKey:@"LineHeight"];
    cssTemplate = [cssTemplate stringByReplacingOccurrencesOfString:@"$LINEHEIGHT$" withString:[NSString stringWithFormat:@"%fem", lineHeight]];
    
    NSArray *backgrounds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Backgrounds"];
    long backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
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
    long backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSString *background = [backgrounds objectAtIndex:backgroundIndex];
    UIColor *backColor = [UIColor blackColor];
    if ([background isEqualToString:@"#FFFFFF"]) {
        backColor = [UIColor whiteColor];
    } else if ([background isEqualToString:@"#F5EFDC"]) {
        backColor = [UIColor colorWithRed:0.96 green:0.94 blue:0.86 alpha:1];
    }
    return backColor;
}

-(void) settingsChanged:(NSString *)setting newValue:(NSUInteger)value {
    BOOL starred = [[NSUserDefaults standardUserDefaults] boolForKey:@"Starred"];
    if (starred != self.item.starredValue) {
        self.item.starredValue = starred;
        if (starred) {
            [[OCNewsHelper sharedHelper] starItemOffline:self.item.myId];
        } else {
            [[OCNewsHelper sharedHelper] unstarItemOffline:self.item.myId];
        }
    }
    
    BOOL unread = [[NSUserDefaults standardUserDefaults] boolForKey:@"Unread"];
    if (unread != self.item.unreadValue) {
        self.item.unreadValue = unread;
        if (unread) {
            [[OCNewsHelper sharedHelper] markItemUnreadOffline:self.item.myId];
        } else {
            [[OCNewsHelper sharedHelper] markItemsReadOffline:[NSMutableSet setWithObject:self.item.myId]];
        }
    }

    [self writeCss];
    if ([self webView] != nil) {
        self.webView.scrollView.backgroundColor = [self myBackgroundColor];
        [self.webView reload];
    }
}

- (BOOL)starred {
    return self.item.starredValue;
}


- (BOOL)unread {
    return self.item.unreadValue;
}


- (void)updateNavigationItemTitle
{
    if (self.isVisible) {
        if ([UIScreen mainScreen].bounds.size.width > 414) { //should cover any phone in landscape and iPad
            if (self.item != nil) {
                if (!loadingComplete && loadingSummary) {
                    self.parentViewController.parentViewController.navigationItem.title = self.item.title;
                } else {
                    self.parentViewController.parentViewController.navigationItem.title = self.webView.title;
                }
            }
        } else {
            self.parentViewController.parentViewController.navigationItem.title = @"";
        }
    }
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    [self updateNavigationItemTitle];
}

- (NSString*)replaceYTIframe:(NSString *)html {
    __block NSString *result = html;
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&error];
    
    if (error) {
        //        NSLog(@"Error: %@", error);
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
                    //                    NSLog(@"Raw: %@", [inputNode rawContents]);
                    
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
                    NSString *embed = [NSString stringWithFormat:@"<embed id=\"yt\" src=\"http://www.youtube.com/embed/%@\" type=\"text/html\" frameborder=\"0\" %@ %@></embed>", videoID, heightString, widthString];
                    result = [result stringByReplacingOccurrencesOfString:[inputNode rawContents] withString:embed];
                }
            }
            if (src && [src rangeOfString:@"vimeo"].location != NSNotFound) {
                NSString *videoID = [self extractVimeoVideoID:src];
                if (videoID) {
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
                    NSString *embed = [NSString stringWithFormat:@"<iframe id=\"vimeo\" src=\"http://player.vimeo.com/video/%@\" type=\"text/html\" frameborder=\"0\" %@ %@></iframe>", videoID, heightString, widthString];
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

//based on http://stackoverflow.com/a/16841070/2036378
- (NSString *)extractVimeoVideoID:(NSString *)urlVimeo {
    NSString *regexString = @"([0-9]{2,11})"; // @"(https?://)?(www.)?(player.)?vimeo.com/([a-z]*/)*([0-9]{6,11})[?]?.*";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:urlVimeo options:0 range:NSMakeRange(0, [urlVimeo length])];
    if(!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
        NSString *substringForFirstMatch = [urlVimeo substringWithRange:rangeOfFirstMatch];
        return substringForFirstMatch;
    }
    
    return nil;
}

@end
