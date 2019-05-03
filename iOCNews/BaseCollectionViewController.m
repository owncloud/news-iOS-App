//
//  BaseCollectionViewController.m
//  iOCNews
//
//  Created by Peter Hedlund on 7/30/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "OCNewsHelper.h"

@interface BaseCollectionViewController () <NSFetchedResultsControllerDelegate> {
    NSMutableArray<NSBlockOperation *> *blockOperations;
}

@end

@implementation BaseCollectionViewController

@synthesize feed = _feed;
@synthesize fetchRequest = _fetchRequest;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize folderId;
@synthesize aboutToFetch;
@synthesize reloadItemsOnUpdate;

- (NSFetchRequest *)fetchRequest {
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:[OCNewsHelper sharedHelper].context];
        _fetchRequest.entity = entity;
        _fetchRequest.fetchBatchSize = 25;
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:NO];
        _fetchRequest.sortDescriptors = @[sort];
    }
    return _fetchRequest;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController == nil) {
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                                        managedObjectContext:[OCNewsHelper sharedHelper].context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
        if (!self.aboutToFetch) {
            return _fetchedResultsController;
        }
        
        NSPredicate *fetchPredicate;
        if (self.feed.myId == -1) {
            fetchPredicate = [NSPredicate predicateWithFormat:@"starred == 1"];
            self.fetchRequest.fetchLimit = self.feed.unreadCount;
        } else {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HideRead"]) {
                if (self.feed.myId == -2) {
                    if (self.folderId > 0) {
                        NSMutableArray *feedsArray = [NSMutableArray new];
                        NSArray *folderFeeds = [[OCNewsHelper sharedHelper] feedsInFolderWithId:self.folderId];
                        __block NSInteger fetchLimit = 0;
                        [folderFeeds enumerateObjectsUsingBlock:^(Feed *feed, NSUInteger idx, BOOL *stop) {
                            [feedsArray addObject:[NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"feedId == %@", @(feed.myId)], [NSPredicate predicateWithFormat:@"unread == 1"] ]]];
                            fetchLimit += feed.articleCount;
                        }];
                        fetchPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:feedsArray];
                        _fetchedResultsController.fetchRequest.fetchLimit = fetchLimit;
                    } else {
                        fetchPredicate = [NSPredicate predicateWithFormat:@"unread == 1"];
                    }
                } else {
                    NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"feedId == %@", @(self.feed.myId)];
                    NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"unread == 1"];
                    NSArray *predArray = @[pred1, pred2];
                    fetchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predArray];
                    _fetchedResultsController.fetchRequest.fetchLimit = self.feed.articleCount;
                }
                _fetchedResultsController.delegate = nil;
            } else {
                if (self.feed.myId == -2) {
                    if (self.folderId > 0) {
                        NSMutableArray *feedsArray = [NSMutableArray new];
                        NSArray *folderFeeds = [[OCNewsHelper sharedHelper] feedsInFolderWithId:self.folderId];
                        __block NSInteger fetchLimit = 0;
                        [folderFeeds enumerateObjectsUsingBlock:^(Feed *feed, NSUInteger idx, BOOL *stop) {
                            [feedsArray addObject:@(feed.myId)];
                            fetchLimit += feed.articleCount;
                        }];
                        fetchPredicate = [NSPredicate predicateWithFormat:@"feedId IN %@", feedsArray];
                        _fetchedResultsController.fetchRequest.fetchLimit = fetchLimit;
                    } else {
                        fetchPredicate = nil;
                        _fetchedResultsController.fetchRequest.fetchLimit = self.feed.articleCount;
                    }
                } else {
                    fetchPredicate = [NSPredicate predicateWithFormat:@"feedId == %@", @(self.feed.myId)];
                    _fetchedResultsController.fetchRequest.fetchLimit = self.feed.articleCount;
                }
                _fetchedResultsController.delegate = self;
            }
        }
        _fetchedResultsController.fetchRequest.predicate = fetchPredicate;
    }
    return _fetchedResultsController;
}

- (void)setFeed:(Feed *)feed {
    _feed = feed;
    _fetchRequest = nil;
    _fetchedResultsController = nil;
//TODO    [self configureView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.reloadItemsOnUpdate = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.fetchedResultsController.fetchedObjects.count;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    blockOperations = [NSMutableArray<NSBlockOperation *> new];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    __weak typeof(self) weakSelf = self;

    if (type == NSFetchedResultsChangeInsert) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [weakSelf.collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]];
        }];
        [blockOperations addObject:operation];
    }
    if (type == NSFetchedResultsChangeDelete) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [weakSelf.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
        }];
        [blockOperations addObject:operation];
    }
    if (type == NSFetchedResultsChangeUpdate) {
        if (self.reloadItemsOnUpdate) {
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                [weakSelf.collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            }];
            [blockOperations addObject:operation];
        }
    }
    if (type == NSFetchedResultsChangeMove) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [weakSelf.collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
        }];
        [blockOperations addObject:operation];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.collectionView performBatchUpdates:^{
        for (NSBlockOperation *operation in self->blockOperations) {
            [operation start];
        }
    } completion:^(BOOL finished) {
        self->blockOperations = nil;
    }];
}

@end
