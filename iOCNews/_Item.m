// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Item.m instead.

#import "_Item.h"

const struct ItemAttributes ItemAttributes = {
	.author = @"author",
	.body = @"body",
	.enclosureLink = @"enclosureLink",
	.enclosureMime = @"enclosureMime",
	.feedId = @"feedId",
	.guid = @"guid",
	.guidHash = @"guidHash",
	.lastModified = @"lastModified",
	.myId = @"myId",
	.pubDate = @"pubDate",
	.readable = @"readable",
	.starred = @"starred",
	.title = @"title",
	.unread = @"unread",
	.url = @"url",
};

const struct ItemRelationships ItemRelationships = {
};

const struct ItemFetchedProperties ItemFetchedProperties = {
};

@implementation ItemID
@end

@implementation _Item

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Item";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Item" inManagedObjectContext:moc_];
}

- (ItemID*)objectID {
	return (ItemID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"feedIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"feedId"];
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
	if ([key isEqualToString:@"pubDateValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"pubDate"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"starredValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"starred"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"unreadValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unread"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic author;






@dynamic body;






@dynamic enclosureLink;






@dynamic enclosureMime;






@dynamic feedId;



- (int32_t)feedIdValue {
	NSNumber *result = [self feedId];
	return [result intValue];
}

- (void)setFeedIdValue:(int32_t)value_ {
	[self setFeedId:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveFeedIdValue {
	NSNumber *result = [self primitiveFeedId];
	return [result intValue];
}

- (void)setPrimitiveFeedIdValue:(int32_t)value_ {
	[self setPrimitiveFeedId:[NSNumber numberWithInt:value_]];
}





@dynamic guid;






@dynamic guidHash;






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





@dynamic pubDate;



- (int32_t)pubDateValue {
	NSNumber *result = [self pubDate];
	return [result intValue];
}

- (void)setPubDateValue:(int32_t)value_ {
	[self setPubDate:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitivePubDateValue {
	NSNumber *result = [self primitivePubDate];
	return [result intValue];
}

- (void)setPrimitivePubDateValue:(int32_t)value_ {
	[self setPrimitivePubDate:[NSNumber numberWithInt:value_]];
}





@dynamic readable;






@dynamic starred;



- (BOOL)starredValue {
	NSNumber *result = [self starred];
	return [result boolValue];
}

- (void)setStarredValue:(BOOL)value_ {
	[self setStarred:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveStarredValue {
	NSNumber *result = [self primitiveStarred];
	return [result boolValue];
}

- (void)setPrimitiveStarredValue:(BOOL)value_ {
	[self setPrimitiveStarred:[NSNumber numberWithBool:value_]];
}





@dynamic title;






@dynamic unread;



- (BOOL)unreadValue {
	NSNumber *result = [self unread];
	return [result boolValue];
}

- (void)setUnreadValue:(BOOL)value_ {
	[self setUnread:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveUnreadValue {
	NSNumber *result = [self primitiveUnread];
	return [result boolValue];
}

- (void)setPrimitiveUnreadValue:(BOOL)value_ {
	[self setPrimitiveUnread:[NSNumber numberWithBool:value_]];
}





@dynamic url;











@end
