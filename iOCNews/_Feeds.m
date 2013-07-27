// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Feeds.m instead.

#import "_Feeds.h"

const struct FeedsAttributes FeedsAttributes = {
	.newestItemId = @"newestItemId",
	.starredCount = @"starredCount",
};

const struct FeedsRelationships FeedsRelationships = {
};

const struct FeedsFetchedProperties FeedsFetchedProperties = {
};

@implementation FeedsID
@end

@implementation _Feeds

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Feeds" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Feeds";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Feeds" inManagedObjectContext:moc_];
}

- (FeedsID*)objectID {
	return (FeedsID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"newestItemIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"newestItemId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"starredCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"starredCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic newestItemId;



- (int32_t)newestItemIdValue {
	NSNumber *result = [self newestItemId];
	return [result intValue];
}

- (void)setNewestItemIdValue:(int32_t)value_ {
	[self setNewestItemId:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveNewestItemIdValue {
	NSNumber *result = [self primitiveNewestItemId];
	return [result intValue];
}

- (void)setPrimitiveNewestItemIdValue:(int32_t)value_ {
	[self setPrimitiveNewestItemId:[NSNumber numberWithInt:value_]];
}





@dynamic starredCount;



- (int32_t)starredCountValue {
	NSNumber *result = [self starredCount];
	return [result intValue];
}

- (void)setStarredCountValue:(int32_t)value_ {
	[self setStarredCount:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveStarredCountValue {
	NSNumber *result = [self primitiveStarredCount];
	return [result intValue];
}

- (void)setPrimitiveStarredCountValue:(int32_t)value_ {
	[self setPrimitiveStarredCount:[NSNumber numberWithInt:value_]];
}










@end
