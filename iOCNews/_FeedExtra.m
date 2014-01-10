// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to FeedExtra.m instead.

#import "_FeedExtra.h"

const struct FeedExtraAttributes FeedExtraAttributes = {
	.articleCount = @"articleCount",
	.lastModified = @"lastModified",
	.preferWeb = @"preferWeb",
	.useReader = @"useReader",
};

const struct FeedExtraRelationships FeedExtraRelationships = {
	.parent = @"parent",
};

const struct FeedExtraFetchedProperties FeedExtraFetchedProperties = {
};

@implementation FeedExtraID
@end

@implementation _FeedExtra

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"FeedExtra" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"FeedExtra";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"FeedExtra" inManagedObjectContext:moc_];
}

- (FeedExtraID*)objectID {
	return (FeedExtraID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"articleCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"articleCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"lastModifiedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"lastModified"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"preferWebValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"preferWeb"];
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





@dynamic parent;

	






@end
