// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Feed.m instead.

#import "_Feed.h"

const struct FeedAttributes FeedAttributes = {
	.added = @"added",
	.faviconLink = @"faviconLink",
	.folderId = @"folderId",
	.link = @"link",
	.myId = @"myId",
	.title = @"title",
	.unreadCount = @"unreadCount",
	.url = @"url",
};

const struct FeedRelationships FeedRelationships = {
	.extra = @"extra",
};

const struct FeedFetchedProperties FeedFetchedProperties = {
};

@implementation FeedID
@end

@implementation _Feed

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Feed";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:moc_];
}

- (FeedID*)objectID {
	return (FeedID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"addedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"added"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"folderIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"folderId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"myIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"myId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"unreadCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unreadCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic added;



- (int32_t)addedValue {
	NSNumber *result = [self added];
	return [result intValue];
}

- (void)setAddedValue:(int32_t)value_ {
	[self setAdded:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveAddedValue {
	NSNumber *result = [self primitiveAdded];
	return [result intValue];
}

- (void)setPrimitiveAddedValue:(int32_t)value_ {
	[self setPrimitiveAdded:[NSNumber numberWithInt:value_]];
}





@dynamic faviconLink;






@dynamic folderId;



- (int32_t)folderIdValue {
	NSNumber *result = [self folderId];
	return [result intValue];
}

- (void)setFolderIdValue:(int32_t)value_ {
	[self setFolderId:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveFolderIdValue {
	NSNumber *result = [self primitiveFolderId];
	return [result intValue];
}

- (void)setPrimitiveFolderIdValue:(int32_t)value_ {
	[self setPrimitiveFolderId:[NSNumber numberWithInt:value_]];
}





@dynamic link;






@dynamic myId;



- (int32_t)myIdValue {
	NSNumber *result = [self myId];
	return [result intValue];
}

- (void)setMyIdValue:(int32_t)value_ {
	[self setMyId:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveMyIdValue {
	NSNumber *result = [self primitiveMyId];
	return [result intValue];
}

- (void)setPrimitiveMyIdValue:(int32_t)value_ {
	[self setPrimitiveMyId:[NSNumber numberWithInt:value_]];
}





@dynamic title;






@dynamic unreadCount;



- (int32_t)unreadCountValue {
	NSNumber *result = [self unreadCount];
	return [result intValue];
}

- (void)setUnreadCountValue:(int32_t)value_ {
	[self setUnreadCount:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveUnreadCountValue {
	NSNumber *result = [self primitiveUnreadCount];
	return [result intValue];
}

- (void)setPrimitiveUnreadCountValue:(int32_t)value_ {
	[self setPrimitiveUnreadCount:[NSNumber numberWithInt:value_]];
}





@dynamic url;






@dynamic extra;

	






@end
