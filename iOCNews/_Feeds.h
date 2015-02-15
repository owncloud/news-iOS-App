// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Feeds.h instead.

#import <CoreData/CoreData.h>

extern const struct FeedsAttributes {
	__unsafe_unretained NSString *newestItemId;
	__unsafe_unretained NSString *starredCount;
} FeedsAttributes;

@interface FeedsID : NSManagedObjectID {}
@end

@interface _Feeds : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) FeedsID* objectID;

@property (nonatomic, strong) NSNumber* newestItemId;

@property (atomic) int32_t newestItemIdValue;
- (int32_t)newestItemIdValue;
- (void)setNewestItemIdValue:(int32_t)value_;

//- (BOOL)validateNewestItemId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* starredCount;

@property (atomic) int32_t starredCountValue;
- (int32_t)starredCountValue;
- (void)setStarredCountValue:(int32_t)value_;

//- (BOOL)validateStarredCount:(id*)value_ error:(NSError**)error_;

@end

@interface _Feeds (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveNewestItemId;
- (void)setPrimitiveNewestItemId:(NSNumber*)value;

- (int32_t)primitiveNewestItemIdValue;
- (void)setPrimitiveNewestItemIdValue:(int32_t)value_;

- (NSNumber*)primitiveStarredCount;
- (void)setPrimitiveStarredCount:(NSNumber*)value;

- (int32_t)primitiveStarredCountValue;
- (void)setPrimitiveStarredCountValue:(int32_t)value_;

@end
