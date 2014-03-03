// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Feed.m instead.

#import "_Feed.h"

const struct FeedAttributes FeedAttributes = {
	.added = @"added",
	.articleCount = @"articleCount",
	.faviconLink = @"faviconLink",
	.folderId = @"folderId",
	.lastModified = @"lastModified",
	.link = @"link",
	.myId = @"myId",
	.preferWeb = @"preferWeb",
	.title = @"title",
	.unreadCount = @"unreadCount",
	.url = @"url",
	.useReader = @"useReader",
};

const struct FeedRelationships FeedRelationships = {
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
	if ([key isEqualToString:@"articleCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"articleCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"folderIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"folderId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"lastModifiedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"lastModified"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"myIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"myId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"preferWebValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"preferWeb"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"unreadCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unreadCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"useReaderValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"useReader"];
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





@dynamic articleCount;



- (int32_t)articleCountValue {
	NSNumber *result = [self articleCount];
	return [result intValue];
}

- (void)setArticleCountValue:(int32_t)value_ {
	[self setArticleCount:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveArticleCountValue {
	NSNumber *result = [self primitiveArticleCount];
	return [result intValue];
}

- (void)setPrimitiveArticleCountValue:(int32_t)value_ {
	[self setPrimitiveArticleCount:[NSNumber numberWithInt:value_]];
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





@dynamic lastModified;



- (int32_t)lastModifiedValue {
	NSNumber *result = [self lastModified];
	return [result intValue];
}

- (void)setLastModifiedValue:(int32_t)value_ {
	[self setLastModified:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveLastModifiedValue {
	NSNumber *result = [self primitiveLastModified];
	return [result intValue];
}

- (void)setPrimitiveLastModifiedValue:(int32_t)value_ {
	[self setPrimitiveLastModified:[NSNumber numberWithInt:value_]];
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





@dynamic preferWeb;



- (BOOL)preferWebValue {
	NSNumber *result = [self preferWeb];
	return [result boolValue];
}

- (void)setPreferWebValue:(BOOL)value_ {
	[self setPreferWeb:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitivePreferWebValue {
	NSNumber *result = [self primitivePreferWeb];
	return [result boolValue];
}

- (void)setPrimitivePreferWebValue:(BOOL)value_ {
	[self setPrimitivePreferWeb:[NSNumber numberWithBool:value_]];
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






@dynamic useReader;



- (BOOL)useReaderValue {
	NSNumber *result = [self useReader];
	return [result boolValue];
}

- (void)setUseReaderValue:(BOOL)value_ {
	[self setUseReader:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveUseReaderValue {
	NSNumber *result = [self primitiveUseReader];
	return [result boolValue];
}

- (void)setPrimitiveUseReaderValue:(BOOL)value_ {
	[self setPrimitiveUseReader:[NSNumber numberWithBool:value_]];
}










@end
