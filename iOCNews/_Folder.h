// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Folder.h instead.

#import <CoreData/CoreData.h>


extern const struct FolderAttributes {
	__unsafe_unretained NSString *myId;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *unreadCount;
} FolderAttributes;

extern const struct FolderRelationships {
} FolderRelationships;

extern const struct FolderFetchedProperties {
} FolderFetchedProperties;






@interface FolderID : NSManagedObjectID {}
@end

@interface _Folder : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (FolderID*)objectID;





@property (nonatomic, strong) NSNumber* myId;



@property int32_t myIdValue;
- (int32_t)myIdValue;
- (void)setMyIdValue:(int32_t)value_;

//- (BOOL)validateMyId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* unreadCount;



@property int32_t unreadCountValue;
- (int32_t)unreadCountValue;
- (void)setUnreadCountValue:(int32_t)value_;

//- (BOOL)validateUnreadCount:(id*)value_ error:(NSError**)error_;






@end

@interface _Folder (CoreDataGeneratedAccessors)

@end

@interface _Folder (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveMyId;
- (void)setPrimitiveMyId:(NSNumber*)value;

- (int32_t)primitiveMyIdValue;
- (void)setPrimitiveMyIdValue:(int32_t)value_;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitiveUnreadCount;
- (void)setPrimitiveUnreadCount:(NSNumber*)value;

- (int32_t)primitiveUnreadCountValue;
- (void)setPrimitiveUnreadCountValue:(int32_t)value_;




@end
