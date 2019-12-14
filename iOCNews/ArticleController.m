//
//  ArticleController.m
//  iOCNews
//
//  Created by Peter Hedlund on 7/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

@import WebKit;

#import "ArticleController.h"
#import "OCNewsHelper.h"
#import "OCSharingProvider.h"
#import "PHPrefViewController.h"
#import "UIColor+PHColor.h"
#import <TUSafariActivity/TUSafariActivity.h>
#import "iOCNews-Swift.h"
#import "UICollectionView+ValidIndexPath.h"
#import "UIColor+PHColor.h"

@interface ArticleController () <UICollectionViewDelegateFlowLayout, WKUIDelegate, WKNavigationDelegate, PHPrefViewControllerDelegate, UIPopoverPresentationControllerDelegate> {
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
@property (nonatomic, strong) ArticleCellWithWebView *currentCell;

@end

@implementation ArticleController

@synthesize selectedArticle;
@synthesize settingsViewController;
@synthesize settingsPresentationController;
@synthesize currentCell;
@synthesize items;

static NSString * const reuseIdentifier = @"ArticleCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    shouldScrollToInitialArticle = YES;
    self.reloadItemsOnUpdate = NO;
    [self.collectionView registerClass:[ArticleCellWithWebView class] forCellWithReuseIdentifier:@"ArticleCellWithWebView"];
    self.view.backgroundColor =  UIColor.ph_cellBackgroundColor;
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ThemeUpdate" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        self.view.backgroundColor =  UIColor.ph_cellBackgroundColor;
    }];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ArticleCellWithWebView *articleCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ArticleCellWithWebView" forIndexPath:indexPath];
    // Configure the cell
    Item *cellItem = (Item *)[self.items objectAtIndex:indexPath.item];
    [articleCell addWebView];
    articleCell.webView.navigationDelegate = self;
    articleCell.webView.UIDelegate = self;
    
    Feed *feed = [OCNewsHelper.sharedHelper feedWithId:cellItem.feedId];
    ItemProviderStruct *itemData = [[ItemProviderStruct alloc] init];
    itemData.title = cellItem.title;
    itemData.myID = cellItem.myId;
    itemData.author = cellItem.author;
    itemData.pubDate = cellItem.pubDate;
    itemData.body = cellItem.body;
    itemData.feedId = cellItem.feedId;
    itemData.starred = cellItem.starred;
    itemData.unread = cellItem.unread;
    itemData.imageLink = cellItem.imageLink;
    itemData.readable = cellItem.readable;
    itemData.url = cellItem.url;
    itemData.favIconLink = feed.faviconLink;
    itemData.feedTitle = feed.title;
    itemData.feedPreferWeb = feed.preferWeb;
    itemData.feedUseReader = feed.useReader;
    ItemProvider *provider = [[ItemProvider alloc] initWithItem:itemData];
    [provider configure];
    articleCell.item = provider;
    if (!currentCell) {
        self.currentCell = articleCell;
    }
    return articleCell;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (shouldScrollToInitialArticle) {
        if (self.selectedArticle) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.items indexOfObject:self.selectedArticle] inSection:0];
            ArticleFlowLayout *layout = (ArticleFlowLayout *)self.collectionView.collectionViewLayout;
            layout.currentIndexPath = indexPath;
            [self.collectionView scrollToItemIfAvailable:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            self.collectionView.contentOffset = [layout targetContentOffsetForProposedContentOffset:CGPointZero];
            if (self.selectedArticle.unread) {
                self.selectedArticle.unread = NO;
                NSMutableSet *set = [NSMutableSet setWithObject:@(self.selectedArticle.myId)];
                [[OCNewsHelper sharedHelper] markItemsReadOffline:set];
            }

            [self updateNavigationItemTitle];
        }
        shouldScrollToInitialArticle = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([scrollView isKindOfClass:[UICollectionView class]]) {
        NSIndexPath *indexPath = [self currentIndexPath];
        ArticleCellWithWebView *cell = (ArticleCellWithWebView *)[self.collectionView cellForItemAtIndexPath:indexPath];
        self.currentCell = cell;
        ArticleFlowLayout *layout =  (ArticleFlowLayout *)self.collectionView.collectionViewLayout;
        layout.currentIndexPath = indexPath;
        Item *item = [self.items objectAtIndex:indexPath.item];
        if (item.unread) {
            item.unread = NO;
            NSMutableSet *set = [NSMutableSet setWithObject:@(item.myId)];
            [[OCNewsHelper sharedHelper] markItemsReadOffline:set];
            [self.articleListcontroller performCellPrefetchForIndexPath:indexPath];
        }
        [self.articleListcontroller.collectionView scrollToItemIfAvailable:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        [self updateNavigationItemTitle];
        [self updateToolbar];
    }
}

#pragma mark - WKWebView delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([webView.URL.scheme isEqualToString:@"file"] || [webView.URL.scheme hasPrefix:@"itms"]) {
        if ([navigationAction.request.URL.absoluteString rangeOfString:@"itunes.apple.com"].location != NSNotFound) {
            [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:nil];
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
                self->loadingComplete = YES;
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
    settingsPresentationController.backgroundColor = [UIColor ph_popoverBackgroundColor];
    [self presentViewController:self.settingsViewController animated:YES completion:nil];
}

#pragma mark - UIPopoverPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - PHPrefViewControllerDelegate

- (void)settingsChanged:(NSString *)setting newValue:(NSUInteger)value {
    BOOL starred = [[NSUserDefaults standardUserDefaults] boolForKey:@"Starred"];
    if (starred != currentCell.item.starred) {
        currentCell.item.starred = starred;
        Item *currentItem = [self currentItem];
        if (currentItem) {
            currentItem.starred = starred;
            [self.articleListcontroller performCellPrefetchForIndexPath:[self currentIndexPath]];
        }
        if (starred) {
            [[OCNewsHelper sharedHelper] starItemOffline:currentCell.item.myId];
        } else {
            [[OCNewsHelper sharedHelper] unstarItemOffline:currentCell.item.myId];
        }
    }
    
    BOOL unread = [[NSUserDefaults standardUserDefaults] boolForKey:@"Unread"];
    if (unread != currentCell.item.unread) {
        currentCell.item.unread = unread;
        Item *currentItem = [self currentItem];
        if (currentItem) {
            currentItem.unread = unread;
            [self.articleListcontroller performCellPrefetchForIndexPath:[self currentIndexPath]];
        }
        if (unread) {
            [[OCNewsHelper sharedHelper] markItemUnreadOffline:currentCell.item.myId];
        } else {
            [[OCNewsHelper sharedHelper] markItemsReadOffline:[NSMutableSet setWithObject:@(currentCell.item.myId)]];
        }
    }
    
    if (currentCell.webView != nil && [setting isEqualToString:@"true"]) {
        [currentCell prepareForReuse];
        [currentCell configureView];
    }
}

- (BOOL)starred {
    return currentCell.item.starred;
}

- (BOOL)unread {
    return currentCell.item.unread;
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

- (NSIndexPath *)currentIndexPath {
    CGFloat currentPage = self.collectionView.contentOffset.x / self.collectionView.frame.size.width;
    return [NSIndexPath indexPathForItem:currentPage inSection:0];
}

- (Item *)currentItem {
    Item *item = [self.items objectAtIndex:[self currentIndexPath].item];
    return item;
}

@end
