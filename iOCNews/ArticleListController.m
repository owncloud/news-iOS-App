//
//  SelectionController.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2012-2016 Peter Hedlund peter.hedlund@me.com
 
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

#import "ArticleListController.h"
#import "NSString+HTML.h"
#import <AFNetworking/AFNetworking.h>
#import "OCArticleImage.h"
#import "RMessage.h"
#import "OCNewsHelper.h"
#import "Item+CoreDataClass.h"
#import "objc/runtime.h"
//#import "UIImageView+OCWebCache.h"
#import "PHThemeManager.h"
#import "UIColor+PHColor.h"
#import "ArticleController.h"
//#import <WebImage/WebImage.h>
#import "iOCNews-Swift.h"

@interface ArticleListController () <UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout> {
    long currentIndex;
    BOOL markingAllItemsRead;
    BOOL hideRead;
    NSArray *fetchedItems;
    BOOL aboutToFetch;
    CGFloat cellContentWidth;
    BOOL comingFromDetail;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *markBarButtonItem;
@property (strong, nonatomic) IBOutlet UIScreenEdgePanGestureRecognizer *sideGestureRecognizer;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *markGesture;

- (void) configureView;
- (void) updateUnreadCount:(NSArray*)itemsToUpdate;
- (void) networkCompleted:(NSNotification*)n;
- (void) networkError:(NSNotification*)n;
- (IBAction)handleCellSwipe:(UISwipeGestureRecognizer *)gestureRecognizer;
- (NSInteger) unreadCount;

@end

@implementation ArticleListController

@synthesize feedRefreshControl;
@synthesize feed = _feed;
@synthesize markGesture;

static NSString * const reuseIdentifier = @"ArticleCell";

#pragma mark - Managing the detail item

- (void)configureView
{
    // Update the user interface for the detail item.
    @try {
        if (self.feed.myId == -2) {
            Folder *folder = [[OCNewsHelper sharedHelper] folderWithId:self.folderId];
            if (folder && folder.name.length) {
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                if ([prefs boolForKey:@"HideRead"]) {
                    self.navigationItem.title = [NSString stringWithFormat:@"All Unread %@ Articles", folder.name];
                } else {
                    self.navigationItem.title = [NSString stringWithFormat:@"All %@ Articles", folder.name];
                }
            } else {
                self.navigationItem.title = self.feed.title;
            }
        } else {
            self.navigationItem.title = self.feed.title;
        }
        hideRead = [[NSUserDefaults standardUserDefaults] boolForKey:@"HideRead"];
        aboutToFetch = YES;
        BOOL success = [self.fetchedResultsController performFetch:nil];
        aboutToFetch = NO;
        if (success) {
            fetchedItems = self.fetchedResultsController.fetchedObjects;
            __block long unreadCount = [self unreadCount];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
                self.markBarButtonItem.enabled = (unreadCount > 0);
            });
        } else {
            fetchedItems = [NSArray new];
        }
    }
    @catch (NSException *exception) {
        self.navigationItem.title = self.feed.title;
    }
    @finally {
        if (self.feed.myId > -2) {
            self.collectionView.refreshControl = self.feedRefreshControl;
        } else {
            self.collectionView.refreshControl = nil;
        }
        [self refresh];
        if (comingFromDetail == NO) {
            if (fetchedItems.count > 0) {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            }
        }
        self.collectionView.scrollsToTop = YES;
    }
}

- (void) refresh {
    long unreadCount = [self unreadCount];
    [self.collectionView reloadData];
    self.markBarButtonItem.enabled = (unreadCount > 0);
}

#pragma mark - View lifecycle

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"HideRead"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"ShowThumbnails"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"ShowFavicons"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.rightBarButtonItem = self.markBarButtonItem;
    self.markBarButtonItem.enabled = NO;
    [self.collectionView registerNib:[UINib nibWithNibName:@"ArticleCellWithThumbnail" bundle:nil] forCellWithReuseIdentifier:@"ArticleCellWithThumbnail"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"NoThumbnailArticleCell" bundle:nil] forCellWithReuseIdentifier:@"NoThumbnailArticleCell"];
    self.collectionView.scrollsToTop = NO;
    [self.collectionView addGestureRecognizer:self.markGesture];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView addGestureRecognizer:self.sideGestureRecognizer];
    
    comingFromDetail = NO;
    markingAllItemsRead = NO;
    aboutToFetch = NO;
    cellContentWidth = 700;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkCompleted:) name:@"NetworkCompleted" object:nil];
    
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification
                                                      object:nil
                                                       queue:mainQueue
                                                  usingBlock:^(NSNotification *notification) {
                                                      [self.collectionView reloadData];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(drawerOpened:)
                                                 name:@"DrawerOpened"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(drawerClosed:)
                                                 name:@"DrawerClosed"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextSaved:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:[OCNewsHelper sharedHelper].context];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ThemeUpdate" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [self.collectionView reloadData];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self configureView];
    comingFromDetail = NO;
}

- (void)contextSaved:(NSNotification*)notification {
    if (markingAllItemsRead) {
        markingAllItemsRead = NO;
        hideRead = [[NSUserDefaults standardUserDefaults] boolForKey:@"HideRead"];
        aboutToFetch= YES;
        BOOL success = [self.fetchedResultsController performFetch:nil];
        aboutToFetch = NO;
        if (success) {
            fetchedItems = self.fetchedResultsController.fetchedObjects;
        }
        [self refresh];
    }
}

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"HideRead"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"ShowThumbnails"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"ShowFavicons"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.fetchedResultsController.delegate = nil;
}

#pragma mark - Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger result = 0;
    if (self.feed)
    {
        id  sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        result = [sectionInfo numberOfObjects];
    }
    return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 154.0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect bounds = collectionView.bounds;
    NSLog(@"Collectionview Width: %f", bounds.size.width);
    if (indexPath.section == 0) {
        return CGSizeMake(bounds.size.width, 154.0);
    } else {
        return CGSizeZero;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    __block Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowThumbnails"] == YES) && item.imageLink) {
        ArticleCellWithThumbnail *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ArticleCellWithThumbnail" forIndexPath:indexPath];
        //    cell.contentWidth = cellContentWidth;
        cell.item = item;
        return cell;
    }
    ArticleCellNoThumbnail *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NoThumbnailArticleCell" forIndexPath:indexPath];
    //        cell.contentWidth = cellContentWidth;
    cell.item = item;
    return cell;

//    cell.tag = indexPath.row;
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowThumbnails"]) {
//        NSString *urlString = [OCArticleImage findImage:summary];
//        if (item.imageLink) {
            //                if (self.tag == indexPath.row) {
            //                    dispatch_main_async_safe(^{
//            [self.articleImage setRoundedImageWithURL:[NSURL URLWithString:urlString]];
//            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:item.imageLink]];
//            [cell.articleImage setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
//                [cell setNeedsLayout];
//            } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
//                [cell setNeedsLayout];
//            }];
//            [cell.articleImage setImageWithURL:[NSURL URLWithString:item.imageLink]]; // placeholderImage:nil options:SDWebImageAvoidAutoSetImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//                [UIView animateWithDuration:0.3f animations:^{
//                    if (cell.item.imageLink && image && (cell.tag == indexPath.row)) {
//                        cell.articleImage.image = image;
//                         [cell setNeedsLayout];
//                    }
//                        cell.articleImage.hidden = NO;
//                        cell.thumbnailContainerWidthConstraint.constant = cell.articleImage.frame.size.width;
//                        cell.articleImageWidthConstraint.constant = cell.articleImage.frame.size.width;
//                        cell.contentContainerLeadingConstraint.constant = cell.articleImage.frame.size.width;
//                    } else {
//                        cell.articleImage.hidden = YES;
//                        cell.thumbnailContainerWidthConstraint.constant = 0.0;
//                        cell.articleImageWidthConstraint.constant = 0.0;
//                        cell.contentContainerLeadingConstraint.constant = 0.0;
//                    }
//
//                }];
//            }];
            //                    });
//                            }
//        } else {
//            cell.articleImage.hidden = YES;
//            cell.thumbnailContainerWidthConstraint.constant = 0.0;
//            cell.articleImageWidthConstraint.constant = 0.0;
//            cell.contentContainerLeadingConstraint.constant = 0.0;
//        }
//    } else {
//        cell.articleImage.hidden = YES;
//        cell.thumbnailContainerWidthConstraint.constant = 0.0;
//        cell.articleImageWidthConstraint.constant = 0.0;
//        cell.contentContainerLeadingConstraint.constant = 0.0;
//    }
//
}


#pragma mark - Table view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    currentIndex = indexPath.row;
    Item *selectedItem = [self.fetchedResultsController.fetchedObjects objectAtIndex: currentIndex];
    if (selectedItem && selectedItem.myId) {
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
        [self performSegueWithIdentifier:@"showArticleSegue" sender:selectedItem];
//
//        
//        [self.navigationController pushViewController:self.articleManagerController animated:YES];
//        [self.articleManagerController navigateToPageAtIndex:currentIndex animated:NO completion:nil];
        if (selectedItem.unread) {
            selectedItem.unread = NO;
            [self updateUnreadCount:@[@(selectedItem.myId)]];
        }
    }
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showArticleSegue"]) {
        ArticleController *articleController = (ArticleController *)segue.destinationViewController;
        articleController.feed = self.feed;
        articleController.folderId = self.folderId;
        articleController.selectedArticle = (Item *)sender;
        articleController.articleListcontroller = self;
        comingFromDetail = YES;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //NSLog(@"We have scrolled");
    hideRead = false;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self markRowsRead];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self markRowsRead];
}


#pragma mark - Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    BOOL result = YES;
    if ([gestureRecognizer isEqual:self.markGesture]) {
        if (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
            NSLog(@"Display Mode: %ld", (long)self.splitViewController.displayMode);
            if (self.splitViewController.displayMode != UISplitViewControllerDisplayModePrimaryHidden) {
                result = NO;
            }
        }
    }
    return result;
}

#pragma mark - Actions

- (IBAction)doRefresh:(id)sender {
    if (self.feed) {
        [[OCNewsHelper sharedHelper] updateFeedWithId:self.feed.myId];
    }
}

- (IBAction)onMarkRead:(id)sender {
    markingAllItemsRead = YES;
    NSMutableArray *idsToMarkRead = [NSMutableArray new];
    long unreadCount = [self unreadCount];
    if (unreadCount > 0) {
        if (self.fetchedResultsController.fetchedObjects.count > 0) {
            NSInteger index = 0;
            for (Item *item in self.fetchedResultsController.fetchedObjects) {
                if (item.unread) {
                    item.unread = NO;
                    [idsToMarkRead addObject:@(item.myId)];
                }
                index += 1;
            }
        }
    }

    self.markBarButtonItem.enabled = NO;
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        [self.navigationController.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
                    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
                } else {
                    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
                }
            } else {
                if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
                    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
                } else {
                    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;
                }
            }
        }];
    }
    [self updateUnreadCount:idsToMarkRead];
}

- (void) markRowsRead {
    @try {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MarkWhileScrolling"]) {
            long unreadCount = [self unreadCount];
            
            if (unreadCount > 0) {
                NSArray *visibleCells = self.collectionView.indexPathsForVisibleItems;
                if (visibleCells.count > 0) {
                    NSInteger topVisibleRow = [[visibleCells valueForKeyPath:@"@min.item"] integerValue];
                    NSLog(@"Top row: %ld", topVisibleRow);
                    if (self.fetchedResultsController.fetchedObjects.count > 0) {
                        NSMutableArray *idsToMarkRead = [NSMutableArray new];
                        NSInteger index = 0;
                        for (Item *item in self.fetchedResultsController.fetchedObjects) {
                            if (index > topVisibleRow) {
                                break;
                            }
                            if (item.unread) {
                                item.unread = NO;
                                [idsToMarkRead addObject:@(item.myId)];
                            }
                            index += 1;
                        }
                        unreadCount = unreadCount - [idsToMarkRead count];
                        [self updateUnreadCount:idsToMarkRead];
//                        dispatch_main_async_safe(^{
                            self.markBarButtonItem.enabled = (unreadCount > 0);
//                        });
                    }
                }
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

- (void)updateUnreadCount:(NSArray *)itemsToUpdate {
    [[OCNewsHelper sharedHelper] markItemsReadOffline:[NSMutableSet setWithArray:itemsToUpdate]];
    [self refresh];
}

- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context {
    if([keyPath isEqual:@"HideRead"]) {
        [self refresh];
    }
    if([keyPath isEqual:@"ShowThumbnails"] || [keyPath isEqual:@"ShowFavicons"]) {
        [self refresh];
    }
}

#pragma mark - Tap navigation

- (UISwipeGestureRecognizer *) markGesture {
    if (!markGesture) {
        markGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleCellSwipe:)];
        markGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        markGesture.delegate = self;
    }
    return markGesture;
}

- (IBAction)handleCellSwipe:(UISwipeGestureRecognizer *)gestureRecognizer {
    //http://stackoverflow.com/a/14364085/2036378 (why it's sometimes a good idea to retrieve the cell)
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint p = [gestureRecognizer locationInView:self.collectionView];
        
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
        if (indexPath == nil) {
            //            NSLog(@"swipe on table view but not on a row");
        } else {
            if (indexPath.section == 0) {
                @try {
                    Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
                    if (item && item.myId) {
                        if (item.unread) {
                            item.unread = NO;
                            [self updateUnreadCount:@[@(item.myId)]];
                        } else {
                            if (item.starred) {
                                item.starred = NO;
                                [[OCNewsHelper sharedHelper] unstarItemOffline:item.myId];
                            } else {
                                item.starred = YES;
                                [[OCNewsHelper sharedHelper] starItemOffline:item.myId];
                            }
                        }
                    }
                }
                @catch (NSException *exception) {
                    //
                }
                @finally {
                    //
                }
                //}
            }
        }
    }
}

- (UIRefreshControl *)feedRefreshControl {
    if (!feedRefreshControl) {
        feedRefreshControl = [[UIRefreshControl alloc] init];
        [feedRefreshControl addTarget:self action:@selector(doRefresh:) forControlEvents:UIControlEventValueChanged];
    }
    
    return feedRefreshControl;
}

- (void)drawerOpened:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NetworkError" object:nil];
    self.collectionView.scrollsToTop = NO;
}

- (void)drawerClosed:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkError:) name:@"NetworkError" object:nil];
    self.collectionView.scrollsToTop = YES;
}

- (void) networkCompleted:(NSNotification *)n {
    [self.collectionView.refreshControl endRefreshing];
}

- (void)networkError:(NSNotification *)n {
    [RMessage showNotificationInViewController:self.navigationController
                                         title:[n.userInfo objectForKey:@"Title"]
                                      subtitle:[n.userInfo objectForKey:@"Message"]
                                     iconImage:nil
                                          type:RMessageTypeError
                                customTypeName:nil
                                      duration:RMessageDurationEndless
                                      callback:nil
                                   buttonTitle:nil
                                buttonCallback:nil
                                    atPosition:RMessagePositionTop
                          canBeDismissedByUser:YES];
}

/*
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
//    [self.collectionView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UICollectionView *collectionView = self.collectionView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]];
            break;
            
        case NSFetchedResultsChangeDelete:
            [collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(ArticleListCell*)[collectionView cellForItemAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            [collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
//    [self.collectionView endUpdates];
    self.markBarButtonItem.enabled = ([self unreadCount] > 0);
}
*/
- (NSInteger)unreadCount {
    NSInteger result = 0;
    if (self.feed) {
        if ((self.feed.myId == -2) && (self.folderId > 0)) {
            Folder *folder = [[OCNewsHelper sharedHelper] folderWithId:self.folderId];
            result = folder.unreadCount;
        } else {
            result = self.feed.unreadCount;
        }
    }
    return result;
}

- (IBAction)onSideGestureRecognizer:(id)sender {
    if ([self.sideGestureRecognizer translationInView:self.collectionView].x > 10) {
        [UIView animateWithDuration:0.3 animations:^{
            self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        } completion:^(BOOL finished) {
            if (finished) {
                [self.collectionView reloadData];
            }
        }];
    }
}

@end
