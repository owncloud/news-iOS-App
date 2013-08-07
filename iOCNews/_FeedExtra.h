// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to FeedExtra.h instead.

#import <CoreData/CoreData.h>


extern const struct FeedExtraAttributes {
	__unsafe_unretained NSString *displayTitle;
	__unsafe_unretained NSString *preferWeb;
	__unsafe_unretained NSString *useReader;
} FeedExtraAttributes;

extern const struct FeedExtraRelationships {
	__unsafe_unretained NSString *parent;
} FeedExtraRelationships;

extern const struct FeedExtraFetchedProperties {
} FeedExtraFetchedProperties;

@class Feed;





@interface FeedExtraID : NSManagedObjectID {}
@end

@interface _FeedExtra : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (FeedExtraID*)objectID;





@property (nonatomic, strong) NSString* displayTitle;



//- (BOOL)validateDisplayTitle:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* preferWeb;



@property BOOL preferWebValue;
- (BOOL)preferWebValue;
- (void)setPreferWebValue:(BOOL)value_;

//- (BOOL)validatePreferWeb:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* useReader;



@property BOOL useReaderValue;
- (BOOL)useReaderValue;
- (void)setUseReaderValue:(BOOL)value_;

//- (BOOL)validateUseReader:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Feed *parent;

//- (BOOL)validateParent:(id*)value_ error:(NSError**)error_;





@end

@interface _FeedExtra (CoreDataGeneratedAccessors)

@end

@interface _FeedExtra (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveDisplayTitle;
- (void)setPrimitiveDisplayTitle:(NSString*)value;




- (NSNumber*)primitivePreferWeb;
- (void)setPrimitivePreferWeb:(NSNumber*)value;

- (BOOL)primitivePreferWebValue;
- (void)setPrimitivePreferWebValue:(BOOL)value_;




- (NSNumber*)primitiveUseReader;
- (void)setPrimitiveUseReader:(NSNumber*)value;

- (BOOL)primitiveUseReaderValue;
- (void)setPrimitiveUseReaderValue:(BOOL)value_;





- (Feed*)primitiveParent;
- (void)setPrimitiveParent:(Feed*)value;


@end
