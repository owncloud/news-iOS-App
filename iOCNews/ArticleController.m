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

@interface ArticleController () <UICollectionViewDelegateFlowLayout, WKUIDelegate, WKNavigationDelegate> {
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

@end

@implementation ArticleController

@synthesize selectedArticle;

static NSString * const reuseIdentifier = @"ArticleCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    shouldScrollToInitialArticle = YES;
    [self.collectionView registerNib:[UINib nibWithNibName:@"ArticleCell" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    [self.fetchedResultsController performFetch:nil];
    // Do any additional setup after loading the view.
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

- (IBAction)onBackBarButton:(id)sender {
   __unused WKNavigation *nav = [currentCell.webView goBack];
}

- (IBAction)onForwardBarButton:(id)sender {
    __unused WKNavigation *nav = [currentCell.webView goForward];
}

- (IBAction)onReloadBarButton:(id)sender {
    __unused WKNavigation *nav = [currentCell.webView reload];
}

- (IBAction)onStopBarButton:(id)sender {
    [currentCell.webView stopLoading];
}

- (IBAction)onActionBarButton:(id)sender {
}

- (IBAction)onMenuBarButton:(id)sender {
}

@end
