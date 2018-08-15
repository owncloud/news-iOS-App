//
//  ArticleController.m
//  iOCNews
//
//  Created by Peter Hedlund on 7/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

@import WebKit;

#import "ArticleController.h"
#import "ArticleCell.h"
#import "OCNewsHelper.h"
#import "OCSharingProvider.h"
#import "PHPrefViewController.h"
#import "UIColor+PHColor.h"
#import <TUSafariActivity/TUSafariActivity.h>

@interface ArticleController () <UICollectionViewDelegateFlowLayout, WKUIDelegate, WKNavigationDelegate, PHPrefViewControllerDelegate, UIPopoverPresentationControllerDelegate> {
    ArticleCell *currentCell;
    BOOL shouldScrollToInitialArticle;
    BOOL loadingComplete;
    BOOL loadingSummary;
}
    
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backBarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *forwardBarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *reloadBarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *stopBarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *actionBarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menuBarButton;

@property (nonatomic, strong, readonly) PHPrefViewController *settingsViewController;
@property (nonatomic, strong, readonly) UIPopoverPresentationController *settingsPresentationController;

@end

@implementation ArticleController

@synthesize selectedArticle;
@synthesize settingsViewController;
@synthesize settingsPresentationController;

static NSString * const reuseIdentifier = @"ArticleCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    shouldScrollToInitialArticle = YES;
    [self.collectionView registerNib:[UINib nibWithNibName:@"ArticleCell" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    [self.fetchedResultsController performFetch:nil];
    [self writeCss];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        NSLog(@"My width = %f", size.width);
        NSIndexPath *currentIndexPath = [self.collectionView indexPathForCell:currentCell];
        [self.collectionView reloadData];
        self.collectionView.contentOffset = CGPointMake(size.width * currentIndexPath.item, 0);
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    [self.fetchedResultsController performFetch:nil];
    NSInteger count = self.fetchedResultsController.fetchedObjects.count;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ArticleCell *articleCell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    // Configure the cell
    Item *cellItem = (Item *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    articleCell.item = cellItem;
    articleCell.webView.navigationDelegate = self;
    articleCell.webView.UIDelegate = self;
    currentCell = articleCell;
    return articleCell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat topBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    topBarHeight += self.navigationController.navigationBar.frame.size.height;
    if (indexPath.section == 0) {
        return CGSizeMake(bounds.size.width, bounds.size.height - topBarHeight);
    } else {
        return CGSizeZero;
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if (shouldScrollToInitialArticle) {
        if (self.selectedArticle) {
            NSArray *articles = self.fetchedResultsController.fetchedObjects;
            NSUInteger initialIndex = [articles indexOfObject:self.selectedArticle];
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:initialIndex inSection:0];
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
            currentCell = (ArticleCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [self updateNavigationItemTitle];
        }
        shouldScrollToInitialArticle = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([scrollView isKindOfClass:[UICollectionView class]]) {
        CGFloat currentPage = self.collectionView.contentOffset.x / self.collectionView.frame.size.width;
        //        NSLog(@"Current page: %f", ceil(currentPage));
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:currentPage inSection:0];
        ArticleCell *cell = (ArticleCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        cell.webView.navigationDelegate = self;
        cell.webView.UIDelegate = self;
        currentCell = cell;
        Item *item = cell.item;
        if (item.unreadValue) {
            item.unreadValue = NO;
            NSMutableSet *set = [NSMutableSet setWithObject:item.myId];
            [[OCNewsHelper sharedHelper] markItemsReadOffline:set];
        }
        [self updateNavigationItemTitle];
        [self updateToolbar];
    }
}

#pragma mark - WKWbView delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([webView.URL.scheme isEqualToString:@"file"] || [webView.URL.scheme hasPrefix:@"itms"]) {
        if ([navigationAction.request.URL.absoluteString rangeOfString:@"itunes.apple.com"].location != NSNotFound) {
            [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
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
    BOOL result = YES; //NO;
    if (currentCell.webView) {
        result = [currentCell.webView.URL.scheme isEqualToString:@"file"] || [currentCell.webView.URL.scheme isEqualToString:@"about"];
    }
    return result;
}

#pragma mark - Toolbar

- (void)updateToolbar {
    //    if (self.isVisible) {
    self.backBarButton.enabled = currentCell.webView.canGoBack;
    self.forwardBarButton.enabled = currentCell.webView.canGoForward;
    UIBarButtonItem *refreshStopBarButtonItem = loadingComplete ? self.reloadBarButton : self.stopBarButton;
    if ((currentCell != nil)) {
        self.actionBarButton.enabled = loadingComplete;
        self.menuBarButton.enabled = loadingComplete;
        refreshStopBarButtonItem.enabled = YES;
    } else {
        self.actionBarButton.enabled = NO;
        self.menuBarButton.enabled = NO;
        refreshStopBarButtonItem.enabled = NO;
    }
    UIBarButtonItem *modeButton = self.splitViewController.displayModeButtonItem;
    if (modeButton) {
        self.navigationItem.leftBarButtonItems = @[modeButton, self.backBarButton, self.forwardBarButton, refreshStopBarButtonItem];
    } else {
        self.navigationItem.leftBarButtonItems = @[self.backBarButton, self.forwardBarButton, refreshStopBarButtonItem];
    }
    self.navigationItem.leftItemsSupplementBackButton = YES;
    //        self.parentViewController.parentViewController.navigationItem.rightBarButtonItems = @[self.textBarButtonItem, self.actionBarButtonItem];
    //    }
}

- (void)updateNavigationItemTitle {
    //    if (self.isVisible) {
    if ([UIScreen mainScreen].bounds.size.width > 414) { //should cover any phone in landscape and iPad
        if (currentCell != nil) {
            if (!loadingComplete && loadingSummary) {
                self.navigationItem.title = currentCell.item.title;
            } else {
                self.navigationItem.title = currentCell.webView.title;
            }
        } else {
            self.navigationItem.title = @"";
        }
    } else {
        self.navigationItem.title = @"";
    }
    //    }
}

#pragma mark - Actions

- (IBAction)onBackBarButton:(id)sender {
    if ([currentCell.webView canGoBack]) {
        __unused WKNavigation *nav = [currentCell.webView goBack];
    }
}

- (IBAction)onForwardBarButton:(id)sender {
    if ([currentCell.webView canGoForward]) {
        __unused WKNavigation *nav = [currentCell.webView goForward];
    }
}

- (IBAction)onReloadBarButton:(id)sender {
    __unused WKNavigation *nav = [currentCell.webView reload];
}

- (IBAction)onStopBarButton:(id)sender {
    [currentCell.webView stopLoading];
    [self updateToolbar];
}

- (IBAction)onActionBarButton:(id)sender {
    NSURL *url = currentCell.webView.URL;
    NSString *subject = currentCell.webView.title;
    if ([[url absoluteString] hasSuffix:@"Documents/summary.html"]) {
        url = [NSURL URLWithString:currentCell.item.url];
        subject = currentCell.item.title;
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
    presentationController.barButtonItem = self.actionBarButton;
}

- (IBAction)onMenuBarButton:(id)sender {
    settingsPresentationController = self.settingsViewController.popoverPresentationController;
    settingsPresentationController.delegate = self;
    settingsPresentationController.barButtonItem = self.menuBarButton;
    settingsPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    settingsPresentationController.backgroundColor = [UIColor popoverBackgroundColor];
    [self presentViewController:self.settingsViewController animated:YES completion:nil];
}

#pragma mark - UIPopoverPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

#pragma mark - PHPrefViewControllerDelegate

- (void)settingsChanged:(NSString *)setting newValue:(NSUInteger)value {
    BOOL starred = [[NSUserDefaults standardUserDefaults] boolForKey:@"Starred"];
    if (starred != currentCell.item.starredValue) {
        currentCell.item.starredValue = starred;
        if (starred) {
            [[OCNewsHelper sharedHelper] starItemOffline:currentCell.item.myId];
        } else {
            [[OCNewsHelper sharedHelper] unstarItemOffline:currentCell.item.myId];
        }
    }
    
    BOOL unread = [[NSUserDefaults standardUserDefaults] boolForKey:@"Unread"];
    if (unread != currentCell.item.unreadValue) {
        currentCell.item.unreadValue = unread;
        if (unread) {
            [[OCNewsHelper sharedHelper] markItemUnreadOffline:currentCell.item.myId];
        } else {
            [[OCNewsHelper sharedHelper] markItemsReadOffline:[NSMutableSet setWithObject:currentCell.item.myId]];
        }
    }
    
    [self writeCss];
    if (currentCell.webView != nil) {
        currentCell.webView.scrollView.backgroundColor = [self myBackgroundColor];
        [currentCell.webView reload];
    }
}

- (BOOL)starred {
    return currentCell.item.starredValue;
}

- (BOOL)unread {
    return currentCell.item.unreadValue;
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

- (void) writeCss {
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

#pragma mark - Lazy Objects

- (PHPrefViewController *)settingsViewController {
    if (!settingsViewController) {
        settingsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"preferences"];
        settingsViewController.preferredContentSize = CGSizeMake(220, 245);
        settingsViewController.modalPresentationStyle = UIModalPresentationPopover;
        settingsViewController.delegate = self;
    }
    return settingsViewController;
}

@end
