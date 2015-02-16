// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Item.h instead.

#import <CoreData/CoreData.h>


extern const struct ItemAttributes {
	__unsafe_unretained NSString *author;
	__unsafe_unretained NSString *body;
	__unsafe_unretained NSString *enclosureLink;
	__unsafe_unretained NSString *enclosureMime;
	__unsafe_unretained NSString *feedId;
	__unsafe_unretained NSString *guid;
	__unsafe_unretained NSString *guidHash;
	__unsafe_unretained NSString *lastModified;
	__unsafe_unretained NSString *myId;
	__unsafe_unretained NSString *pubDate;
	__unsafe_unretained NSString *readable;
	__unsafe_unretained NSString *starred;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *unread;
	__unsafe_unretained NSString *url;
} ItemAttributes;

extern const struct ItemRelationships {
} ItemRelationships;

extern const struct ItemFetchedProperties {
} ItemFetchedProperties;


















@interface ItemID : NSManagedObjectID {}
@end

@interface _Item : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ItemID*)objectID;





@property (nonatomic, strong) NSString* author;



//- (BOOL)validateAuthor:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* body;



//- (BOOL)validateBody:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* enclosureLink;



//- (BOOL)validateEnclosureLink:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* enclosureMime;



//- (BOOL)validateEnclosureMime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* feedId;



@property int32_t feedIdValue;
- (int32_t)feedIdValue;
- (void)setFeedIdValue:(int32_t)value_;

//- (BOOL)validateFeedId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* guid;



//- (BOOL)validateGuid:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* guidHash;



//- (BOOL)validateGuidHash:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* lastModified;



@property int32_t lastModifiedValue;
- (int32_t)lastModifiedValue;
- (void)setLastModifiedValue:(int32_t)value_;

//- (BOOL)validateLastModified:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* myId;



@property int32_t myIdValue;
- (int32_t)myIdValue;
- (void)setMyIdValue:(int32_t)value_;

//- (BOOL)validateMyId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* pubDate;



@property int32_t pubDateValue;
- (int32_t)pubDateValue;
- (void)setPubDateValue:(int32_t)value_;

//- (BOOL)validatePubDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* readable;



//- (BOOL)validateReadable:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* starred;



@property BOOL starredValue;
- (BOOL)starredValue;
- (void)setStarredValue:(BOOL)value_;

//- (BOOL)validateStarred:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* title;



//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* unread;



@property BOOL unreadValue;
- (BOOL)unreadValue;
- (void)setUnreadValue:(BOOL)value_;

//- (BOOL)validateUnread:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* url;



//- (BOOL)validateUrl:(id*)value_ error:(NSError**)error_;






@end

@interface _Item (CoreDataGeneratedAccessors)

@end

@interface _Item (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveAuthor;
- (void)setPrimitiveAuthor:(NSString*)value;




- (NSString*)primitiveBody;
- (void)setPrimitiveBody:(NSString*)value;




- (NSString*)primitiveEnclosureLink;
- (void)setPrimitiveEnclosureLink:(NSString*)value;




- (NSString*)primitiveEnclosureMime;
- (void)setPrimitiveEnclosureMime:(NSString*)value;




- (NSNumber*)primitiveFeedId;
- (void)setPrimitiveFeedId:(NSNumber*)value;

- (int32_t)primitiveFeedIdValue;
- (void)setPrimitiveFeedIdValue:(int32_t)value_;




- (NSString*)primitiveGuid;
- (void)setPrimitiveGuid:(NSString*)value;




- (NSString*)primitiveGuidHash;
- (void)setPrimitiveGuidHash:(NSString*)value;




- (NSNumber*)primitiveLastModified;
- (void)setPrimitiveLastModified:(NSNumber*)value;

- (int32_t)primitiveLastModifiedValue;
- (void)setPrimitiveLastModifiedValue:(int32_t)value_;




- (NSNumber*)primitiveMyId;
- (void)setPrimitiveMyId:(NSNumber*)value;

- (int32_t)primitiveMyIdValue;
- (void)setPrimitiveMyIdValue:(int32_t)value_;




- (NSNumber*)primitivePubDate;
- (void)setPrimitivePubDate:(NSNumber*)value;

- (int32_t)primitivePubDateValue;
- (void)setPrimitivePubDateValue:(int32_t)value_;




- (NSString*)primitiveReadable;
- (void)setPrimitiveReadable:(NSString*)value;




- (NSNumber*)primitiveStarred;
- (void)setPrimitiveStarred:(NSNumber*)value;

- (BOOL)primitiveStarredValue;
- (void)setPrimitiveStarredValue:(BOOL)value_;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSNumber*)primitiveUnread;
- (void)setPrimitiveUnread:(NSNumber*)value;

- (BOOL)primitiveUnreadValue;
- (void)setPrimitiveUnreadValue:(BOOL)value_;




- (NSString*)primitiveUrl;
- (void)setPrimitiveUrl:(NSString*)value;




@end
