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
#import "OCAPIClient.h"
#import "Feeds.h"
#import "Feed.h"
#import "Item.h"
#import "NSDictionary+HandleNull.h"

@interface OCNewsHelper () {
    NSMutableArray *feedsToAdd;
    NSMutableArray *feedsToDelete;
    NSMutableArray *itemsToMarkRead;
    NSMutableArray *itemsToMarkUnread;
    NSMutableArray *itemsToStar;
    NSMutableArray *itemsToUnstar;
}

- (int)addFeedFromDictionary:(NSDictionary*)dict;
- (void)addItemFromDictionary:(NSDictionary*)dict;

@end

@implementation OCNewsHelper

@synthesize context;
@synthesize objectModel;
@synthesize coordinator;
@synthesize feedsRequest;
@synthesize feedRequest;
@synthesize itemRequest;

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
    Feeds *newFeeds = [NSEntityDescription insertNewObjectForEntityForName:@"Feeds" inManagedObjectContext:self.context];
    newFeeds.starredCount = [NSNumber numberWithInt:0];
    newFeeds.newestItemId = [NSNumber numberWithInt:0];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    feedsToAdd = [[prefs arrayForKey:@"FeedsToAdd"] mutableCopy];
    feedsToDelete = [[prefs arrayForKey:@"FeedsToDelete"] mutableCopy];
    itemsToMarkRead = [[prefs arrayForKey:@"ItemsToMarkRead"] mutableCopy];
    itemsToMarkUnread = [[prefs arrayForKey:@"ItemsToMarkUnread"] mutableCopy];
    itemsToStar = [[prefs arrayForKey:@"ItemsToStar"] mutableCopy];
    itemsToUnstar = [[prefs arrayForKey:@"ItemsToUnstar"] mutableCopy];

    [self saveContext];

    __unused int status = [[OCAPIClient sharedClient] networkReachabilityStatus];

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
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:feedsToAdd forKey:@"FeedsToAdd"];
    [prefs setObject:feedsToDelete forKey:@"FeedsToDelete"];
    [prefs setObject:itemsToMarkRead forKey:@"ItemsToMarkRead"];
    [prefs setObject:itemsToMarkUnread forKey:@"ItemsToMarkUnread"];
    [prefs setObject:itemsToStar forKey:@"ItemsToStar"];
    [prefs setObject:itemsToUnstar forKey:@"ItemsToUnstar"];
    [prefs synchronize];
    
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
    newFeed.url = [dict objectForKeyNotNull:@"url" fallback:@""];
    newFeed.title = [dict objectForKeyNotNull:@"title" fallback:@""];
    newFeed.faviconLink = [dict objectForKeyNotNull:@"faviconLink" fallback:@"favicon"];
    newFeed.added = [dict objectForKey:@"added"];
    newFeed.folderId = [dict objectForKey:@"folderId"];
    newFeed.unreadCount = [dict objectForKey:@"unreadCount"];
    newFeed.link = [dict objectForKeyNotNull:@"link" fallback:@""];
    [self addFeedExtra:newFeed];
    return newFeed.myIdValue;
}

- (void)addItemFromDictionary:(NSDictionary *)dict {
    Item *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:self.context];
    newItem.myId = [dict objectForKey:@"id"];
    newItem.guid = [dict objectForKey:@"guid"];
    newItem.guidHash = [dict objectForKey:@"guidHash"];
    newItem.url = [dict objectForKeyNotNull:@"url" fallback:@""];
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
    [self.itemRequest setPredicate:[NSPredicate predicateWithFormat:@"feedId == %@", feed.myId]];
    
    NSError *error = nil;
    NSArray *feedItems = [self.context executeFetchRequest:self.itemRequest error:&error];
    for (Item *item in feedItems) {
        [self.context deleteObject:item];
    }
    [self.context deleteObject:feed];
    [self updateTotalUnreadCount];
}

- (void)sync {
    if ([[OCAPIClient sharedClient] networkReachabilityStatus] > 0) {
        [[OCAPIClient sharedClient] getPath:@"feeds" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self updateFeeds:responseObject];
            [self updateItems];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSString *message = [NSString stringWithFormat:@"The server repsonded '%@' and the error reported was '%@'", [NSHTTPURLResponse localizedStringForStatusCode:operation.response.statusCode], [error localizedDescription]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Error Updating Feeds", @"Title", message, @"Message", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkError" object:self userInfo:userInfo];
        }];
        
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Unable to Reach Server", @"Title",
                                  @"Please check network connection and login.", @"Message", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkError" object:self userInfo:userInfo];
    }
    
}

- (void)updateFeeds:(id)JSON {
    //Remove previous
    NSError *error = nil;
    NSArray *oldFeeds = [self.context executeFetchRequest:self.feedRequest error:&error];
    NSArray *knownIds = [oldFeeds valueForKey:@"myId"];
    
    NSLog(@"Count: %i", oldFeeds.count);
    
    error = nil;
    NSArray *feeds = [self.context executeFetchRequest:self.feedsRequest error:&error];
    
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
        
        for (NSNumber *feedId in feedsToDelete) {
            Feed *feed = [self feedWithId:[feedId integerValue]];
            [self deleteFeedOffline:feed]; //the feed will have been readded as new on server
        }
        [feedsToDelete removeAllObjects];
        
        for (NSString *urlString in feedsToAdd) {
            [self addFeedOffline:urlString];
        }
        [feedsToAdd removeAllObjects];
    }
    [self updateTotalUnreadCount];
}

- (Feed*)feedWithId:(int)anId {
    NSDictionary *subs = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anId] forKey:@"FEED_ID"];
    NSArray *myFeeds = [self.context executeFetchRequest:[self.objectModel fetchRequestFromTemplateWithName:@"feedWithIdRequest" substitutionVariables:subs] error:nil];
    return (Feed*)[myFeeds lastObject];
}

- (Item*)itemWithId:(NSNumber *)anId {
    [self.itemRequest setPredicate:[NSPredicate predicateWithFormat:@"myId == %@", anId]];
    NSArray *myItems = [self.context executeFetchRequest:self.itemRequest error:nil];
    return (Item*)[myItems lastObject];
}

- (int)itemCount {
    [self.itemRequest setPredicate:nil];
    NSError *error = nil;
    NSArray *items = [self.context executeFetchRequest:self.itemRequest error:&error];
    NSLog(@"Count: %i", items.count);
    return items.count;
}

- (void)updateItems {
    if ([self itemCount] > 0) {
        //NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-86400];
        //[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[date timeIntervalSince1970]] forKey:@"LastModified"];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey:@"LastModified"]], @"lastModified",
                                [NSNumber numberWithInt:3], @"type",
                                [NSNumber numberWithInt:0], @"id", nil];
        
        [[OCAPIClient sharedClient] getPath:@"items/updated" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *jsonDict = (NSDictionary *) responseObject;
            NSArray *newItems = [NSArray arrayWithArray:[jsonDict objectForKey:@"items"]];
            
            if (newItems.count > 0) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]] forKey:@"LastModified"];
                
                __block NSMutableSet *possibleDuplicateItems = [NSMutableSet new];
                __block NSMutableSet *feedsWithNewItems = [NSMutableSet new];
                [newItems enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop ) {
                    [possibleDuplicateItems addObject:[item objectForKey:@"id"]];
                    [feedsWithNewItems addObject:[item objectForKey:@"feedId"]];
                }];
                NSLog(@"Item count: %i; possibleDuplicateItems count: %i", newItems.count, possibleDuplicateItems.count);
                [self.itemRequest setPredicate:[NSPredicate predicateWithFormat: @"myId IN %@", possibleDuplicateItems]];
                
                NSError *error = nil;
                NSArray *duplicateItems = [self.context executeFetchRequest:self.itemRequest error:&error];
                NSLog(@"duplicateItems Count: %i", duplicateItems.count);
                
                for (NSManagedObject *item in duplicateItems) {
                    NSLog(@"Deleting duplicate with title: %@", ((Item*)item).title);
                    [self.context deleteObject:item];
                }
                
                [newItems enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop ) {
                    [self addItemFromDictionary:item];
                }];
                
                NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:NO];
                [self.itemRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
                
                [feedsWithNewItems enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                    [self.itemRequest setPredicate:[NSPredicate predicateWithFormat: @"feedId == %@", obj]];
                    
                    NSError *error = nil;
                    NSMutableArray *feedItems = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:self.itemRequest error:&error]];
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
                [self markItemsReadOffline:itemsToMarkRead];
                [itemsToMarkRead removeAllObjects];
                for (NSNumber *itemId in itemsToStar) {
                    [self starItemOffline:itemId];
                }
                [itemsToStar removeAllObjects];
                for (NSNumber *itemId in itemsToUnstar) {
                    [self unstarItemOffline:itemId];
                }
                [itemsToUnstar removeAllObjects];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkSuccess" object:self userInfo:nil];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSString *message = [NSString stringWithFormat:@"The server repsonded '%@' and the error reported was '%@'", [NSHTTPURLResponse localizedStringForStatusCode:operation.response.statusCode], [error localizedDescription]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Error Updating Items", @"Title", message, @"Message", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkError" object:self userInfo:userInfo];
        }];
    } else { //first time
        __block NSMutableArray *operations = [NSMutableArray new];
        __block NSMutableArray *addedItems = [NSMutableArray new];
        __block OCAPIClient *client = [OCAPIClient sharedClient];
        
        NSError *error = nil;
        NSArray *feeds = [self.context executeFetchRequest:self.feedRequest error:&error];
        
        [feeds enumerateObjectsUsingBlock:^(Feed *feed, NSUInteger idx, BOOL *stop) {
            
            NSDictionary *itemParams = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:200], @"batchSize",
                                        [NSNumber numberWithInt:0], @"offset",
                                        [NSNumber numberWithInt:0], @"type",
                                        feed.myId, @"id",
                                        @"true", @"getRead", nil];
            
            NSMutableURLRequest *itemURLRequest = [client requestWithMethod:@"GET" path:@"items" parameters:itemParams];
            
            AFJSONRequestOperation *itemOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:itemURLRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                
                //NSLog(@"New Items: %@", JSON);
                NSDictionary *jsonDict = (NSDictionary *) JSON;
                NSArray *newItems = [NSArray arrayWithArray:[jsonDict objectForKey:@"items"]];
                [addedItems addObjectsFromArray:newItems];
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                NSString *message = [NSString stringWithFormat:@"The server repsonded '%@' and the error reported was '%@'", [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode], [error localizedDescription]];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Error Updating Items", @"Title", message, @"Message", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkError" object:self userInfo:userInfo];
            }];
            BOOL allowInvalid = [[NSUserDefaults standardUserDefaults] boolForKey:@"AllowInvalidSSLCertificate"];
            if (allowInvalid) {
                [itemOperation setWillSendRequestForAuthenticationChallengeBlock:^(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge) {
                    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
                    }
                    
                }];
            }
            
            [operations addObject:itemOperation];
        }];
        
        [client enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
            NSLog(@"Feed %i of %i", numberOfFinishedOperations, totalNumberOfOperations);
        } completionBlock:^(NSArray *operations) {
            [addedItems enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop ) {
                [self addItemFromDictionary:item];
            }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkSuccess" object:self userInfo:nil];
        }];
    }
    
    [self updateTotalUnreadCount];
}

- (void)updateReadItems:(NSArray *)items {
    [self.itemRequest setPredicate:[NSPredicate predicateWithFormat: @"myId IN %@", items]];

    NSError *error = nil;
    NSArray *allItems = [self.context executeFetchRequest:self.itemRequest error:&error];
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
    [self.itemRequest setPredicate:[NSPredicate predicateWithFormat: @"starred == 1"]];
    
    NSError *error = nil;
    NSArray *starredItems = [self.context executeFetchRequest:self.itemRequest error:&error];
    if (!starredItems || error) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    NSLog(@"Count: %i", starredItems.count);
    
    error = nil;
    NSArray *feeds = [self.context executeFetchRequest:self.feedsRequest error:&error];
    if (!feeds || error) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    Feeds *theFeeds = [feeds lastObject];
    theFeeds.starredCountValue = starredItems.count;
    
    [[self feedWithId:-1] setUnreadCountValue:starredItems.count];
    [self saveContext];
}

- (void)addFeedOffline:(NSString *)urlString {
    if ([[OCAPIClient sharedClient] networkReachabilityStatus] > 0) {
        //online
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:urlString, @"url", [NSNumber numberWithInt:0], @"folderId", nil];
        
        [[OCAPIClient sharedClient] postPath:@"feeds" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Feeds: %@", responseObject);
            
            int newFeedId = [self addFeed:responseObject];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:200], @"batchSize",
                                    [NSNumber numberWithInt:0], @"offset",
                                    [NSNumber numberWithInt:0], @"type",
                                    [NSNumber numberWithInt:newFeedId], @"id",
                                    [NSNumber numberWithInt:1], @"getRead", nil];
            
            [[OCAPIClient sharedClient] getPath:@"items" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSDictionary *jsonDict = (NSDictionary *) responseObject;
                NSArray *newItems = [NSArray arrayWithArray:[jsonDict objectForKey:@"items"]];
                [newItems enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop ) {
                    [self addItemFromDictionary:item];
                }];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSString *message = [NSString stringWithFormat:@"The server repsonded '%@' and the error reported was '%@'", [NSHTTPURLResponse localizedStringForStatusCode:operation.response.statusCode], [error localizedDescription]];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Error Retrieving Items", @"Title", message, @"Message", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkError" object:self userInfo:userInfo];
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSString *message = [NSString stringWithFormat:@"The server repsonded '%@' and the error reported was '%@'", [NSHTTPURLResponse localizedStringForStatusCode:operation.response.statusCode], [error localizedDescription]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Error Adding Feed", @"Title", message, @"Message", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkError" object:self userInfo:userInfo];
        }];
    
    } else {
        //offline
        [feedsToAdd addObject:urlString];
        Feed *newFeed = [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:self.context];
        newFeed.myId = [NSNumber numberWithInt:10000 + feedsToAdd.count];
        newFeed.url = urlString;
        newFeed.title = urlString;
        newFeed.faviconLink = @"favicon";
        newFeed.added = [NSNumber numberWithInt:1];
        newFeed.folderId = [NSNumber numberWithInt:0];
        newFeed.unreadCount = [NSNumber numberWithInt:0];
        newFeed.link = @"";
        //[feedsToDelete addObject:[NSNumber numberWithInt:10000 + feedsToAdd.count]]; //should be deleted when we get the real feed
    }
    [self updateTotalUnreadCount];
}

- (void) deleteFeedOffline:(Feed*)feed {
    if ([[OCAPIClient sharedClient] networkReachabilityStatus] > 0) {
        //online
        NSString *path = [NSString stringWithFormat:@"feeds/%@", [feed.myId stringValue]];
        [[OCAPIClient sharedClient] deletePath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success");
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure");
            NSString *message = [NSString stringWithFormat:@"The error reported was '%@'", [error localizedDescription]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Error Deleting Feed", @"Title", message, @"Message", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkError" object:self userInfo:userInfo];
        }];
    } else {
        //offline
        [feedsToDelete addObject:feed.myId];
    }
    [self deleteFeed:feed];
}

- (void)markItemsReadOffline:(NSArray *)itemIds {
    if ([[OCAPIClient sharedClient] networkReachabilityStatus] > 0) {
        //online
        [[OCAPIClient sharedClient] putPath:@"items/read/multiple" parameters:[NSDictionary dictionaryWithObject:itemIds forKey:@"items"] success:nil failure:nil];
    } else {
        //offline
        [itemsToMarkRead addObjectsFromArray:itemIds];
    }
    [self updateReadItems:itemIds];
}

- (void)markItemUnreadOffline:(NSNumber*)itemId {
    //
}

- (void)starItemOffline:(NSNumber*)itemId {
    if ([[OCAPIClient sharedClient] networkReachabilityStatus] > 0) {
        //online
        Item *item = [self itemWithId:itemId];
        if (item) {
            NSString *path = [NSString stringWithFormat:@"items/%@/%@/star", [item.feedId stringValue], item.guidHash];
            [[OCAPIClient sharedClient] putPath:path parameters:nil success:nil failure:nil];
        }
    } else {
        //offline
        NSInteger i = [itemsToUnstar indexOfObject:itemId];
        if (i != NSNotFound) {
            [itemsToUnstar removeObject:itemId];
        }
        [itemsToStar addObject:itemId];
    }
    [self updateStarredCount];
}

- (void)unstarItemOffline:(NSNumber*)itemId {
    if ([[OCAPIClient sharedClient] networkReachabilityStatus] > 0) {
        //online
        Item *item = [self itemWithId:itemId];
        if (item) {
            NSString *path = [NSString stringWithFormat:@"items/%@/%@/unstar", [item.feedId stringValue], item.guidHash];
            [[OCAPIClient sharedClient] putPath:path parameters:nil success:nil failure:nil];
        }
    } else {
        //offline
        NSInteger i = [itemsToStar indexOfObject:itemId];
        if (i != NSNotFound) {
            [itemsToStar removeObject:itemId];
        }
        [itemsToUnstar addObject:itemId];
    }
    [self updateStarredCount];
}

- (NSFetchRequest *)feedsRequest {
    if (!feedsRequest) {
        feedsRequest = [[NSFetchRequest alloc] init];
        [feedsRequest setEntity:[NSEntityDescription entityForName:@"Feeds" inManagedObjectContext:self.context]];
    }
    return feedsRequest;
}

- (NSFetchRequest *)feedRequest {
    if (!feedRequest) {
        feedRequest = [[NSFetchRequest alloc] init];
        [feedRequest setEntity:[NSEntityDescription entityForName:@"Feed" inManagedObjectContext:self.context]];
        feedRequest.predicate = nil;
    }
    return feedRequest;
}

- (NSFetchRequest *)itemRequest {
    if (!itemRequest) {
        itemRequest = [[NSFetchRequest alloc] init];
        [itemRequest setEntity:[NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.context]];
        itemRequest.predicate = nil;
    }
    return itemRequest;
}
- (NSURL*) documentsDirectoryURL {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
