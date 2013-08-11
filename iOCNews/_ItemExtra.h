// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ItemExtra.h instead.

#import <CoreData/CoreData.h>


extern const struct ItemExtraAttributes {
	__unsafe_unretained NSString *readable;
} ItemExtraAttributes;

extern const struct ItemExtraRelationships {
	__unsafe_unretained NSString *parent;
} ItemExtraRelationships;

extern const struct ItemExtraFetchedProperties {
} ItemExtraFetchedProperties;

@class Item;



@interface ItemExtraID : NSManagedObjectID {}
@end

@interface _ItemExtra : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ItemExtraID*)objectID;





@property (nonatomic, strong) NSString* readable;



//- (BOOL)validateReadable:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Item *parent;

//- (BOOL)validateParent:(id*)value_ error:(NSError**)error_;





@end

@interface _ItemExtra (CoreDataGeneratedAccessors)

@end

@interface _ItemExtra (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveReadable;
- (void)setPrimitiveReadable:(NSString*)value;





- (Item*)primitiveParent;
- (void)setPrimitiveParent:(Item*)value;


@end
