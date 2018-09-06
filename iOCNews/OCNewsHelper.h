//
//  OCNewsHelper.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Folder+CoreDataClass.h"
#import "Feed+CoreDataClass.h"
#import "Item+CoreDataClass.h"

// the type of the query (Feed: 0, Folder: 1, Starred: 2, All: 3)
typedef NS_ENUM(NSInteger, OCUpdateType) {
    OCUpdateTypeFeed,
    OCUpdateTypeFolder,
    OCUpdateTypeStarred,
    OCUpdateTypeAll
};

@interface OCNewsHelper : NSObject

@property (nonatomic,retain) NSManagedObjectContext *context;
@property (nonatomic, retain) NSManagedObjectModel *objectModel;
@property (nonatomic, retain) NSPersistentStoreCoordinator *coordinator;

@property (nonatomic, strong, readonly) NSFetchRequest *feedsRequest;
@property (nonatomic, strong, readonly) NSFetchRequest *folderRequest;
@property (nonatomic, strong, readonly) NSFetchRequest *feedRequest;
@property (nonatomic, strong, readonly) NSFetchRequest *itemRequest;

+ (OCNewsHelper *)sharedHelper;
- (NSManagedObjectContext *)context;
- (NSURL *)documentsDirectoryURL;
- (NSManagedObjectModel *)objectModel;
- (NSPersistentStoreCoordinator *)coordinator;
- (void)saveContext;

- (void)sync:(void (^)(UIBackgroundFetchResult))completionHandler;

- (Folder*)folderWithId:(NSInteger)anId;
- (NSArray*)folders;
- (Feed*)feedWithId:(NSInteger)anId;
- (NSArray*)feedsInFolderWithId:(NSInteger)folderId;
- (Item*)itemWithId:(NSInteger)anId;
- (void)faviconForFeedWithId:(NSInteger)feedId imageView:(UIImageView *)imageView;
- (int)addFolder:(id)JSON;
- (void)deleteFolder:(Folder*)folder;
- (void)updateFolders;
- (void)updateFolderWithId:(NSInteger)anId;
- (int)addFeed:(id)JSON;
- (void)deleteFeed:(Feed*)feed;
- (void)updateFeeds:(id)JSON;
- (void)updateFeedWithId:(NSInteger)anId;
- (void)updateReadItems:(NSArray*)items;
- (void)updateFolderUnreadCount;
- (void)updateTotalUnreadCount;
- (void)updateStarredCount;
- (long)feedCount;
- (long)itemCount;

- (void)addFolderOffline:(NSString*)name;
- (void)deleteFolderOffline:(Folder*)folder;
- (void)renameFolderOfflineWithId:(NSInteger)anId To:(NSString*)newName;
- (void)addFeedOffline:(NSString*)urlString;
- (void)deleteFeedOffline:(Feed*)feed;
- (void)moveFeedOfflineWithId:(NSInteger)aFeedId toFolderWithId:(NSInteger)aFolderId;
- (void)renameFeedOfflineWithId:(NSInteger)anId To:(NSString*)newName;
- (void)markItemsReadOffline:(NSMutableSet*)itemIds;
- (void)markItemUnreadOffline:(NSInteger)itemId;
- (void)starItemOffline:(NSInteger)itemId;
- (void)unstarItemOffline:(NSInteger)itemId;

@end
