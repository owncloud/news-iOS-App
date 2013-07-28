//
//  OCNewsHelper.m
//  iOCNews
//
//  Created by Peter Hedlund on 7/24/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "OCNewsHelper.h"
#import "Feeds.h"
#import "Feed.h"
#import "Item.h"

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
    
    Feeds *newFeeds = [NSEntityDescription insertNewObjectForEntityForName:@"Feeds" inManagedObjectContext:self.context];
    newFeeds.starredCount = [NSNumber numberWithInt:0];
    newFeeds.newestItemId = [NSNumber numberWithInt:0];
    
    NSError *saveError = nil;
    if ([self.context save:&saveError]) {
        NSLog(@"Feed saved");
    } else {
        NSLog(@"Error occured while saving");
        return nil;
    }

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
        
        NSError *error = nil;
        coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self objectModel]];
        if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
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
    if (context != nil) {
        if ([context hasChanges] && ![context save:&error]) {
            NSLog(@"Error %@, %@", error, [error userInfo]);
            //abort();
        }
    }
}

#pragma mark - COREDATA -INSERT

- (int)addFeed:(id)JSON {
    NSDictionary *jsonDict = (NSDictionary *) JSON;
    NSMutableArray *newFeeds = [jsonDict objectForKey:@"feeds"];
    NSDictionary *feed = [newFeeds lastObject];
    Feed *newFeed = [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:self.context];
    newFeed.id = [feed objectForKey:@"id"];
    newFeed.url = [feed objectForKey:@"url"];
    newFeed.title = [feed objectForKey:@"title"];
    id val = [feed objectForKey:@"faviconLink"];
    newFeed.faviconLink = (val == [NSNull null] ? @"favicon" : val);
    newFeed.added = [feed objectForKey:@"added"];
    newFeed.folderId = [feed objectForKey:@"folderId"];
    newFeed.unreadCount = [feed objectForKey:@"unreadCount"];
    newFeed.link = [feed objectForKey:@"link"];
    
    [self updateTotalUnreadCount];
    return newFeed.idValue;
}

- (void)deleteFeed:(id)feed {
    [self.context deleteObject:feed];
    [self updateTotalUnreadCount];
}

- (void)updateFeeds:(id)JSON {
    //Remove previous
    NSFetchRequest *oldFeedsFetcher = [[NSFetchRequest alloc] init];
    [oldFeedsFetcher setEntity:[NSEntityDescription entityForName:@"Feed" inManagedObjectContext:self.context]];
    [oldFeedsFetcher setIncludesPropertyValues:NO]; //only fetch the managedObjectID

    NSError *error = nil;
    NSArray *oldFeeds = [self.context executeFetchRequest:oldFeedsFetcher error:&error];
    
    
    NSLog(@"Count: %i", oldFeeds.count);
    
    for (NSManagedObject *feed in oldFeeds) {
        [self.context deleteObject:feed];
    }
    
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

    Feed *allFeed = [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:self.context];
    allFeed.id = [NSNumber numberWithInt:-2];
    allFeed.url = @"";
    allFeed.title = @"All Articles";
    allFeed.faviconLink = @"favicon";
    allFeed.added = [NSNumber numberWithInt:1];
    allFeed.folderId = [NSNumber numberWithInt:0];
    allFeed.unreadCount = [NSNumber numberWithInt:0];
    allFeed.link = @"";

    Feed *starredFeed = [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:self.context];
    starredFeed.id = [NSNumber numberWithInt:-1];
    starredFeed.url = @"";
    starredFeed.title = @"Starred";
    starredFeed.faviconLink = @"star_icon";
    starredFeed.added = [NSNumber numberWithInt:2];
    starredFeed.folderId = [NSNumber numberWithInt:0];
    starredFeed.unreadCount = theFeeds.starredCount;
    starredFeed.link = @"";
    
    [newFeeds enumerateObjectsUsingBlock:^(NSDictionary *feed, NSUInteger idx, BOOL *stop ) {
        Feed *newFeed = [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:self.context];
        newFeed.id = [feed objectForKey:@"id"];
        newFeed.url = [feed objectForKey:@"url"];
        newFeed.title = [feed objectForKey:@"title"];
        id val = [feed objectForKey:@"faviconLink"];
        newFeed.faviconLink = (val == [NSNull null] ? @"favicon" : val);
        newFeed.added = [feed objectForKey:@"added"];
        newFeed.folderId = [feed objectForKey:@"folderId"];
        newFeed.unreadCount = [feed objectForKey:@"unreadCount"];
        newFeed.link = [feed objectForKey:@"link"];
    }];
    
    [self updateTotalUnreadCount];
}

- (Feed*)feedWithId:(int)id {
    NSDictionary *subs = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:id] forKey:@"FEED_ID"];
    NSArray *myFeeds = [self.context executeFetchRequest:[self.objectModel fetchRequestFromTemplateWithName:@"feedWithIdRequest" substitutionVariables:subs] error:nil];
    return (Feed*)[myFeeds lastObject];
}

- (void)updateItems:(NSArray*)items {
    NSFetchRequest *oldItemsFetcher = [[NSFetchRequest alloc] init];
    [oldItemsFetcher setEntity:[NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.context]];
    [oldItemsFetcher setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *oldItems = [self.context executeFetchRequest:oldItemsFetcher error:&error];
    
    
    NSLog(@"Count: %i", oldItems.count);
    if (oldItems.count == 0) {
        //first time
        //Add the new items        
        [items enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop ) {
            Item *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:self.context];
            newItem.id = [item objectForKey:@"id"];
            newItem.guid = [item objectForKey:@"guid"];
            newItem.guidHash = [item objectForKey:@"guidHash"];
            newItem.url = [item objectForKey:@"url"];
            newItem.title = [item objectForKey:@"title"];
            id val = [item objectForKey:@"author"];
            newItem.author = (val == [NSNull null] ? @"" : val);
            newItem.pubDate = [item objectForKey:@"pubDate"];
            newItem.body = [item objectForKey:@"body"];
            val = [item objectForKey:@"enclosureMime"];
            newItem.enclosureMime = (val == [NSNull null] ? @"" : val);
            val = [item objectForKey:@"enclosureLink"];
            newItem.enclosureLink = (val == [NSNull null] ? @"" : val);
            newItem.feedId = [item objectForKey:@"feedId"];
            newItem.unread = [item objectForKey:@"unread"];
            newItem.starred = [item objectForKey:@"starred"];
            newItem.lastModified = [item objectForKey:@"lastModified"];
        }];

    } else {
        //updating
    }
    
    [self updateTotalUnreadCount];
}

- (void)updateTotalUnreadCount {
    NSArray *unreadFeeds = [self.context executeFetchRequest:[self.objectModel fetchRequestTemplateForName:@"totalUnreadRequest"] error:nil];
    __block int i = 0;
    [unreadFeeds enumerateObjectsUsingBlock:^(Feed *obj, NSUInteger idx, BOOL *stop) {
        if (obj.idValue >= 0) {
            i = i + obj.unreadCountValue;
        }
    }];
    [[self feedWithId:-2] setUnreadCountValue:i];
    NSError *saveError = nil;
    if ([self.context save:&saveError]) {
        NSLog(@"Feed saved");
    } else {
        NSLog(@"Error occured while saving");
    }
}

- (NSURL*) documentsDirectoryURL {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
