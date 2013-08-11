// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ItemExtra.m instead.

#import "_ItemExtra.h"

const struct ItemExtraAttributes ItemExtraAttributes = {
	.readable = @"readable",
};

const struct ItemExtraRelationships ItemExtraRelationships = {
	.parent = @"parent",
};

const struct ItemExtraFetchedProperties ItemExtraFetchedProperties = {
};

@implementation ItemExtraID
@end

@implementation _ItemExtra

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ItemExtra" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ItemExtra";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ItemExtra" inManagedObjectContext:moc_];
}

- (ItemExtraID*)objectID {
	return (ItemExtraID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic readable;






@dynamic parent;

	






@end
