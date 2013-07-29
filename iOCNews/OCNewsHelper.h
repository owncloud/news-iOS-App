//
//  OCNewsHelper.h
//  iOCNews
//
//  Created by Peter Hedlund on 7/24/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Feed.h"

@interface OCNewsHelper : NSObject

@property (nonatomic,retain) NSManagedObjectContext *context;
@property (nonatomic, retain) NSManagedObjectModel *objectModel;
@property (nonatomic, retain) NSPersistentStoreCoordinator *coordinator;

+ (OCNewsHelper *)sharedHelper;
- (NSManagedObjectContext *)context;
- (NSURL *)documentsDirectoryURL;
- (NSManagedObjectModel *)objectModel;
- (NSPersistentStoreCoordinator *)coordinator;
- (void)saveContext;

- (Feed*)feedWithId:(int)anId;

- (int)addFeed:(id)JSON;
- (void)deleteFeed:(Feed*)feed;
- (void)updateFeeds:(id)JSON;
- (void)updateItems:(NSArray*)items;
- (void)updateReadItems:(NSArray*)items;
- (void)updateTotalUnreadCount;
- (void)updateStarredCount;
- (int)itemCount;

/*
-(void) insertContactInfoName :(NSString *)name Address:(NSString *)address PhoneNo:(NSString *)phoneNO;
-(void) selectAllContacts;
-(NSManagedObject *) searchContactInfoByName :(NSString *) name;
-(void) deleteContactInfoByName:(NSString *) name;
*/
@end
