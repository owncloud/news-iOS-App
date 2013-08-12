//
//  OCNewsHelper.m
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

#import "OCNewsHelper.h"
#import "Feeds.h"
#import "Feed.h"
#import "Item.h"
#import "NSDictionary+HandleNull.h"

@interface OCNewsHelper ()

- (int)addFeedFromDictionary:(NSDictionary*)dict;
- (void)addItemFromDictionary:(NSDictionary*)dict;

@end

@implementation OCNewsHelper

@synthesize context;
@synthesize objectModel;
@synthesize coordinator;

+ (OCNewsHelper*)sharedHelper {
    static dispatch_once_t once_token;
    static id sharedHelper;
    dispatch_once(&once_token, ^{
        sharedHelper = [[OCNewsHelper alloc] init];
    });
    return sharedHelper;
}

- (OCNewsHelper*)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    //TODO: Is this really needed?
    Feeds *newFeeds = [NSEntityDescription insertNewObjectForEntityForName:@"Feeds" inManagedObjectContext:self.context];
    newFeeds.starredCount = [NSNumber numberWithInt:0];
    newFeeds.newestItemId = [NSNumber numberWithInt:0];
    
    [self saveContext];

    return self;
}

- (NSManagedObjectModel *)objectModel {
    if (!objectModel) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"News" withExtension:@"momd"];
        objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return objectModel;
}

- (NSPersistentStoreCoordinator *)coordinator {
    if (!coordinator) {
        NSURL *storeURL = [self documentsDirectoryURL];
        storeURL = [storeURL URLByAppendingPathComponent:@"News.sqlite"];
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
                                  NSInferMappingModelAutomaticallyOption : @YES };
        NSError *error = nil;
        coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self objectModel]];
        if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
            NSLog(@"Error %@, %@", error, [error localizedDescription]);
            abort();
        }
    }
    return coordinator;
}

- (NSManagedObjectContext *)context {
    if (!context) {
        NSPersistentStoreCoordinator *myCoordinator = [self coordinator];
        if (myCoordinator != nil) {
            context = [[NSManagedObjectContext alloc] init];
            [context setPersistentStoreCoordinator:myCoordinator];
        }
    }
    return context;
}

- (void)saveContext {
    NSError *error = nil;
    if (self.context != nil) {
        if ([self.context hasChanges] && ![self.context save:&error]) {
            NSLog(@"Error saving data %@, %@", error, [error userInfo]);
            //abort();
        } else {
            NSLog(@"Data saved");
        }
    }
}

#pragma mark - COREDATA -INSERT

- (int)addFeedFromDictionary:(NSDictionary *)dict {
    Feed *newFeed = [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:self.context];
    newFeed.myId = [dict objectForKey:@"id"];
    newFeed.url = [dict objectForKey:@"url"];
    newFeed.title = [dict objectForKeyNotNull:@"title" fallback:@""];
    newFeed.faviconLink = [dict objectForKeyNotNull:@"faviconLink" fallback:@"favicon"];
    newFeed.added = [dict objectForKey:@"added"];
    newFeed.folderId = [dict objectForKey:@"folderId"];
    newFeed.unreadCount = [dict objectForKey:@"unreadCount"];
    newFeed.link = [dict objectForKey:@"link"];
    [self addFeedExtra:newFeed];
    return newFeed.myIdValue;
}

- (void)addItemFromDictionary:(NSDictionary *)dict {
    Item *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:self.context];
    newItem.myId = [dict objectForKey:@"id"];
    newItem.guid = [dict objectForKey:@"guid"];
    newItem.guidHash = [dict objectForKey:@"guidHash"];
    newItem.url = [dict objectForKey:@"url"];
    newItem.title = [dict objectForKeyNotNull:@"title" fallback:@""];
    newItem.author = [dict objectForKeyNotNull:@"author" fallback:@""];
    newItem.pubDate = [dict objectForKeyNotNull:@"pubDate" fallback:nil];
    newItem.body = [dict objectForKeyNotNull:@"body" fallback:@""];
    newItem.enclosureMime = [dict objectForKeyNotNull:@"enclosureMime" fallback:@""];
    newItem.enclosureLink = [dict objectForKeyNotNull:@"enclosureLink" fallback:@""];
    newItem.feedId = [dict objectForKey:@"feedId"];
    newItem.unread = [dict objectForKey:@"unread"];
    newItem.starred = [dict objectForKey:@"starred"];
    newItem.lastModified = [dict objectForKey:@"lastModified"];
    [self addItemExtra:newItem];
}

- (int)addFeed:(id)JSON {
    NSDictionary *jsonDict = (NSDictionary *) JSON;
    NSMutableArray *newFeeds = [jsonDict objectForKey:@"feeds"];
    int newFeedId = [self addFeedFromDictionary:[newFeeds lastObject]];
    [self updateTotalUnreadCount];
    return newFeedId;
}

- (void)addFeedExtra:(Feed *)feed {
    FeedExtra *extra = [NSEntityDescription insertNewObjectForEntityForName:@"FeedExtra" inManagedObjectContext:self.context];
    extra.displayTitle = feed.title;
    extra.parent = feed;
    feed.extra = extra;
}

- (void)addItemExtra:(Item *)item {
    ItemExtra *extra = [NSEntityDescription insertNewObjectForEntityForName:@"ItemExtra" inManagedObjectContext:self.context];
    extra.parent = item;
    item.extra = extra;
}

- (void)deleteFeed:(Feed*)feed {
    NSFetchRequest *feedItemsFetcher = [[NSFetchRequest alloc] init];
    [feedItemsFetcher setEntity:[NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.context]];
    [feedItemsFetcher setIncludesPropertyValues:NO];
    [feedItemsFetcher setPredicate:[NSPredicate predicateWithFormat:@"feedId == %@", feed.myId]];
    
    NSError *error = nil;
    NSArray *feedItems = [self.context executeFetchRequest:feedItemsFetcher error:&error];
    for (Item *item in feedItems) {
        [self.context deleteObject:item];
    }
    [self.context deleteObject:feed];
    [self updateTotalUnreadCount];
}

- (void)updateFeeds:(id)JSON {
    //Remove previous
    NSFetchRequest *oldFeedsFetcher = [[NSFetchRequest alloc] init];
    [oldFeedsFetcher setEntity:[NSEntityDescription entityForName:@"Feed" inManagedObjectContext:self.context]];

    NSError *error = nil;
    NSArray *oldFeeds = [self.context executeFetchRequest:oldFeedsFetcher error:&error];
    NSArray *knownIds = [oldFeeds valueForKey:@"myId"];
    
    NSLog(@"Count: %i", oldFeeds.count);
    
    NSFetchRequest *feedsFetcher = [[NSFetchRequest alloc] init];
    [feedsFetcher setEntity:[NSEntityDescription entityForName:@"Feeds" inManagedObjectContext:self.context]];
    
    error = nil;
    NSArray *feeds = [self.context executeFetchRequest:feedsFetcher error:&error];
    
    //Add the new feeds
    NSDictionary *jsonDict = (NSDictionary *) JSON;
    Feeds *theFeeds = [feeds objectAtIndex:0];
    theFeeds.starredCount = [jsonDict objectForKey:@"starredCount"];
    theFeeds.newestItemId = [jsonDict objectForKey:@"newestItemId"];

    NSArray *newFeeds = [NSArray arrayWithArray:[jsonDict objectForKey:@"feeds"]];
    
    NSArray *newIds = [newFeeds valueForKey:@"id"];
    NSLog(@"Known: %@; New: %@", knownIds, newIds);

    if (oldFeeds.count == 0) {
        Feed *allFeed = [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:self.context];
        allFeed.myId = [NSNumber numberWithInt:-2];
        allFeed.url = @"";
        allFeed.title = @"All Articles";
        allFeed.faviconLink = @"favicon";
        allFeed.added = [NSNumber numberWithInt:1];
        allFeed.folderId = [NSNumber numberWithInt:0];
        allFeed.unreadCount = [NSNumber numberWithInt:0];
        allFeed.link = @"";
        
        Feed *starredFeed = [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:self.context];
        starredFeed.myId = [NSNumber numberWithInt:-1];
        starredFeed.url = @"";
        starredFeed.title = @"Starred";
        starredFeed.faviconLink = @"star_icon";
        starredFeed.added = [NSNumber numberWithInt:2];
        starredFeed.folderId = [NSNumber numberWithInt:0];
        starredFeed.unreadCount = theFeeds.starredCount;
        starredFeed.link = @"";
        
        [newFeeds enumerateObjectsUsingBlock:^(NSDictionary *feed, NSUInteger idx, BOOL *stop ) {
            [self addFeedFromDictionary:feed];
        }];
    } else {
        NSMutableArray *newOnServer = [NSMutableArray arrayWithArray:newIds];
        [newOnServer removeObjectsInArray:knownIds];
        NSLog(@"New on server: %@", newOnServer);
        [newOnServer enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSPredicate * predicate = [NSPredicate predicateWithFormat:@"id == %@", obj];
            NSArray * matches = [newFeeds filteredArrayUsingPredicate:predicate];
            if (matches.count > 0) {
                [self addFeedFromDictionary:[matches lastObject]];
            }
        }];
        
        NSMutableArray *deletedOnServer = [NSMutableArray arrayWithArray:knownIds];
        [deletedOnServer removeObjectsInArray:newIds];
        [deletedOnServer filterUsingPredicate:[NSPredicate predicateWithFormat:@"self >= 0"]];
        NSLog(@"Deleted on server: %@", deletedOnServer);
        while (deletedOnServer.count > 0) {
            Feed *feedToRemove = [self feedWithId:[[deletedOnServer lastObject] integerValue]];
            [self.context deleteObject:feedToRemove];
            [deletedOnServer removeLastObject];
        }
        [newFeeds enumerateObjectsUsingBlock:^(NSDictionary *feedDict, NSUInteger idx, BOOL *stop) {
            Feed *feed = [self feedWithId:[[feedDict objectForKey:@"id"] integerValue]];
            feed.unreadCount = [feedDict objectForKey:@"unreadCount"];
        }];
    }
    [self updateTotalUnreadCount];
}

- (Feed*)feedWithId:(int)anId {
    NSDictionary *subs = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anId] forKey:@"FEED_ID"];
    NSArray *myFeeds = [self.context executeFetchRequest:[self.objectModel fetchRequestFromTemplateWithName:@"feedWithIdRequest" substitutionVariables:subs] error:nil];
    return (Feed*)[myFeeds lastObject];
}

- (int)itemCount {
    NSFetchRequest *itemsFetcher = [[NSFetchRequest alloc] init];
    [itemsFetcher setEntity:[NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.context]];
    [itemsFetcher setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *items = [self.context executeFetchRequest:itemsFetcher error:&error];
    NSLog(@"Count: %i", items.count);
    return items.count;
}

- (void)updateItems:(NSArray*)items {
    if ([self itemCount] == 0) {
        //first time
        //Add the new items        
        [items enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop ) {
            [self addItemFromDictionary:item];
        }];

    } else {
        //updating
        __block NSMutableSet *possibleDuplicateItems = [NSMutableSet new];
        __block NSMutableSet *feedsWithNewItems = [NSMutableSet new];
        [items enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop ) {
            [possibleDuplicateItems addObject:[item objectForKey:@"id"]];
            [feedsWithNewItems addObject:[item objectForKey:@"feedId"]];
        }];
        NSLog(@"Item count: %i; possibleDuplicateItems count: %i", items.count, possibleDuplicateItems.count);
        NSFetchRequest *itemsFetcher = [[NSFetchRequest alloc] init];
        [itemsFetcher setEntity:[NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.context]];
        [itemsFetcher setPredicate:[NSPredicate predicateWithFormat: @"myId IN %@", possibleDuplicateItems]];
        
        NSError *error = nil;
        NSArray *duplicateItems = [self.context executeFetchRequest:itemsFetcher error:&error];
        NSLog(@"duplicateItems Count: %i", duplicateItems.count);

        for (NSManagedObject *item in duplicateItems) {
            NSLog(@"Deleting duplicate with title: %@", ((Item*)item).title);
            [self.context deleteObject:item];
        }

        [items enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop ) {
            [self addItemFromDictionary:item];
        }];
        
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:NO];
        [itemsFetcher setSortDescriptors:[NSArray arrayWithObject:sort]];
        
        [feedsWithNewItems enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            [itemsFetcher setPredicate:[NSPredicate predicateWithFormat: @"feedId == %@", obj]];
            
            NSError *error = nil;
            NSMutableArray *feedItems = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:itemsFetcher error:&error]];
            if (feedItems.count > 200) {
                NSLog(@"Ids: %@", [feedItems valueForKey:@"myId"]);
                NSLog(@"FeedId: %@; Count: %i", obj, feedItems.count);
                //int i = feedItems.count;
                while (feedItems.count > 200) {
                    Item *itemToRemove = [feedItems lastObject];
                    if (!itemToRemove.starredValue) {
                        NSLog(@"Deleting item with id %i and title %@", itemToRemove.myIdValue, itemToRemove.title);
                        [self.context deleteObject:itemToRemove];
                        [feedItems removeLastObject];
                    }
                }
            }
        }];

    }
    
    [self updateTotalUnreadCount];
}

- (void)updateReadItems:(NSArray *)items {
    NSFetchRequest *itemsFetcher = [[NSFetchRequest alloc] init];
    [itemsFetcher setEntity:[NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.context]];
    [itemsFetcher setPredicate:[NSPredicate predicateWithFormat: @"myId IN %@", items]];

    NSError *error = nil;
    NSArray *allItems = [self.context executeFetchRequest:itemsFetcher error:&error];
    if (!allItems || error) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    NSLog(@"Count: %i", items.count);
    
    [allItems enumerateObjectsUsingBlock:^(Item *item, NSUInteger idx, BOOL *stop) {
            item.unreadValue = NO;
            Feed *feed = [self feedWithId:item.feedIdValue];
            --feed.unreadCountValue;
    }];
    [self updateTotalUnreadCount];
}

- (void)updateTotalUnreadCount {
    NSArray *unreadFeeds = [self.context executeFetchRequest:[self.objectModel fetchRequestTemplateForName:@"totalUnreadRequest"] error:nil];
    __block int i = 0;
    [unreadFeeds enumerateObjectsUsingBlock:^(Feed *obj, NSUInteger idx, BOOL *stop) {
        if (obj.myIdValue >= 0) {
            i = i + obj.unreadCountValue;
        }
    }];
    [[self feedWithId:-2] setUnreadCountValue:i];
    [self saveContext];
}

- (void)updateStarredCount {
    NSFetchRequest *itemsFetcher = [[NSFetchRequest alloc] init];
    [itemsFetcher setEntity:[NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.context]];
    [itemsFetcher setPredicate:[NSPredicate predicateWithFormat: @"starred == 1"]];
    
    NSError *error = nil;
    NSArray *starredItems = [self.context executeFetchRequest:itemsFetcher error:&error];
    if (!starredItems || error) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    NSLog(@"Count: %i", starredItems.count);
    
    NSFetchRequest *feedsFetcher = [[NSFetchRequest alloc] init];
    [feedsFetcher setEntity:[NSEntityDescription entityForName:@"Feeds" inManagedObjectContext:self.context]];
    
    error = nil;
    NSArray *feeds = [self.context executeFetchRequest:feedsFetcher error:&error];
    if (!feeds || error) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    Feeds *theFeeds = [feeds lastObject];
    theFeeds.starredCountValue = starredItems.count;
    
    [[self feedWithId:-1] setUnreadCountValue:starredItems.count];
    [self saveContext];
}

- (NSURL*) documentsDirectoryURL {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
