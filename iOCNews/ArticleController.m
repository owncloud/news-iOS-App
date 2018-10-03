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
@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@end

@implementation ArticleController

@synthesize selectedArticle;
@synthesize settingsViewController;
@synthesize settingsPresentationController;
@synthesize currentCell;
@synthesize currentIndexPath;

static NSString * const reuseIdentifier = @"ArticleCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    shouldScrollToInitialArticle = YES;
    [self.collectionView registerClass:[ArticleCellWithWebView class] forCellWithReuseIdentifier:@"ArticleCellWithWebView"];
    UICollectionViewFlowLayout *layout =  (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        CGFloat width = self.view.frame.size.width;
        CGFloat height = self.view.frame.size.height;
        layout.itemSize = CGSizeMake(width, height);
        [layout invalidateLayout];
    } else if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        CGFloat width = self.view.frame.size.width;
        CGFloat height = self.view.frame.size.height - self.collectionView.contentInset.top - 1;
        layout.itemSize = CGSizeMake(width, height);
    }
    [self.fetchedResultsController performFetch:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    CGFloat offsetWidth = 0.0;
    
    UICollectionViewFlowLayout *layout =  (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        CGFloat width = self.view.frame.size.height;
        CGFloat height = self.view.frame.size.width;
        layout.itemSize = CGSizeMake(width, height);
        offsetWidth = width;
    } else if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        CGFloat width = self.view.frame.size.height;
        CGFloat height = self.view.frame.size.width - self.collectionView.contentInset.top - 1;
        layout.itemSize = CGSizeMake(width, height);
        offsetWidth = width;
    }
    [layout invalidateLayout];

    if (currentCell) {
        self.currentIndexPath = [self.collectionView indexPathForCell:currentCell];
    }
    self.collectionView.contentOffset = CGPointMake(offsetWidth * self.currentIndexPath.item, 0);
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
    ArticleCellWithWebView *articleCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ArticleCellWithWebView" forIndexPath:indexPath];
    // Configure the cell
    Item *cellItem = (Item *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    [articleCell addWebView];
    articleCell.webView.navigationDelegate = self;
    articleCell.webView.UIDelegate = self;
    articleCell.item = cellItem;
    if (!currentCell) {
        self.currentCell = articleCell;
    }

    return articleCell;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (shouldScrollToInitialArticle) {
        if (self.selectedArticle) {
            NSArray *articles = self.fetchedResultsController.fetchedObjects;
            NSUInteger initialIndex = [articles indexOfObject:self.selectedArticle];
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:initialIndex inSection:0];
            NSLog(@"Content insets: %f, %f", self.collectionView.contentInset.top, self.collectionView.contentInset.bottom);
            NSLog(@"Collection view height: %f", self.collectionView.frame.size.height);
            UICollectionViewFlowLayout *layout =  (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
            NSLog(@"Item height: %f", layout.itemSize.height);
            NSLog(@"Section insets: %f, %f", layout.sectionInset.top, layout.sectionInset.bottom);

            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
//            ArticleCellWithWebView *cell = (ArticleCellWithWebView *)[self.collectionView cellForItemAtIndexPath:indexPath];
//            self.currentCell = cell;
            self.currentIndexPath = indexPath;
            self.collectionView.contentOffset = CGPointMake(layout.itemSize.width * self.currentIndexPath.item, 0);

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
        ArticleCellWithWebView *cell = (ArticleCellWithWebView *)[self.collectionView cellForItemAtIndexPath:indexPath];
//        cell.webView.navigationDelegate = self;
//        cell.webView.UIDelegate = self;
        self.currentCell = cell;
        self.currentIndexPath = indexPath;
        Item *item = cell.item;
        if (item.unread) {
            item.unread = NO;
            NSMutableSet *set = [NSMutableSet setWithObject:@(item.myId)];
            [[OCNewsHelper sharedHelper] markItemsReadOffline:set];
        }
        [self.articleListcontroller.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
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
    if (starred != currentCell.item.starred) {
        currentCell.item.starred = starred;
        if (starred) {
            [[OCNewsHelper sharedHelper] starItemOffline:currentCell.item.myId];
        } else {
            [[OCNewsHelper sharedHelper] unstarItemOffline:currentCell.item.myId];
        }
    }
    
    BOOL unread = [[NSUserDefaults standardUserDefaults] boolForKey:@"Unread"];
    if (unread != currentCell.item.unread) {
        currentCell.item.unread = unread;
        if (unread) {
            [[OCNewsHelper sharedHelper] markItemUnreadOffline:currentCell.item.myId];
        } else {
            [[OCNewsHelper sharedHelper] markItemsReadOffline:[NSMutableSet setWithObject:@(currentCell.item.myId)]];
        }
    }
    
    if (currentCell.webView != nil) {
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

@end
