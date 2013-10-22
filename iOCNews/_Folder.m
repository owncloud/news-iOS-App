// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Folder.m instead.

#import "_Folder.h"

const struct FolderAttributes FolderAttributes = {
	.lastModified = @"lastModified",
	.myId = @"myId",
	.name = @"name",
	.unreadCount = @"unreadCount",
};

const struct FolderRelationships FolderRelationships = {
};

const struct FolderFetchedProperties FolderFetchedProperties = {
};

@implementation FolderID
@end

@implementation _Folder

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Folder" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Folder";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Folder" inManagedObjectContext:moc_];
}

- (FolderID*)objectID {
	return (FolderID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
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
	if ([key isEqualToString:@"unreadCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unreadCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
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





@dynamic name;






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










@end
