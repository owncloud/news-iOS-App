// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Feed.h instead.

#import <CoreData/CoreData.h>


extern const struct FeedAttributes {
	__unsafe_unretained NSString *added;
	__unsafe_unretained NSString *articleCount;
	__unsafe_unretained NSString *faviconLink;
	__unsafe_unretained NSString *folderId;
	__unsafe_unretained NSString *lastModified;
	__unsafe_unretained NSString *link;
	__unsafe_unretained NSString *myId;
	__unsafe_unretained NSString *preferWeb;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *unreadCount;
	__unsafe_unretained NSString *url;
	__unsafe_unretained NSString *useReader;
} FeedAttributes;

extern const struct FeedRelationships {
} FeedRelationships;

extern const struct FeedFetchedProperties {
} FeedFetchedProperties;















@interface FeedID : NSManagedObjectID {}
@end

@interface _Feed : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (FeedID*)objectID;





@property (nonatomic, strong) NSNumber* added;



@property int32_t addedValue;
- (int32_t)addedValue;
- (void)setAddedValue:(int32_t)value_;

//- (BOOL)validateAdded:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* articleCount;



@property int32_t articleCountValue;
- (int32_t)articleCountValue;
- (void)setArticleCountValue:(int32_t)value_;

//- (BOOL)validateArticleCount:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* faviconLink;



//- (BOOL)validateFaviconLink:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* folderId;



@property int32_t folderIdValue;
- (int32_t)folderIdValue;
- (void)setFolderIdValue:(int32_t)value_;

//- (BOOL)validateFolderId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* lastModified;



@property int32_t lastModifiedValue;
- (int32_t)lastModifiedValue;
- (void)setLastModifiedValue:(int32_t)value_;

//- (BOOL)validateLastModified:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* link;



//- (BOOL)validateLink:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* myId;



@property int32_t myIdValue;
- (int32_t)myIdValue;
- (void)setMyIdValue:(int32_t)value_;

//- (BOOL)validateMyId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* preferWeb;



@property BOOL preferWebValue;
- (BOOL)preferWebValue;
- (void)setPreferWebValue:(BOOL)value_;

//- (BOOL)validatePreferWeb:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* title;



//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* unreadCount;



@property int32_t unreadCountValue;
- (int32_t)unreadCountValue;
- (void)setUnreadCountValue:(int32_t)value_;

//- (BOOL)validateUnreadCount:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* url;



//- (BOOL)validateUrl:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* useReader;



@property BOOL useReaderValue;
- (BOOL)useReaderValue;
- (void)setUseReaderValue:(BOOL)value_;

//- (BOOL)validateUseReader:(id*)value_ error:(NSError**)error_;






@end

@interface _Feed (CoreDataGeneratedAccessors)

@end

@interface _Feed (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveAdded;
- (void)setPrimitiveAdded:(NSNumber*)value;

- (int32_t)primitiveAddedValue;
- (void)setPrimitiveAddedValue:(int32_t)value_;




- (NSNumber*)primitiveArticleCount;
- (void)setPrimitiveArticleCount:(NSNumber*)value;

- (int32_t)primitiveArticleCountValue;
- (void)setPrimitiveArticleCountValue:(int32_t)value_;




- (NSString*)primitiveFaviconLink;
- (void)setPrimitiveFaviconLink:(NSString*)value;




- (NSNumber*)primitiveFolderId;
- (void)setPrimitiveFolderId:(NSNumber*)value;

- (int32_t)primitiveFolderIdValue;
- (void)setPrimitiveFolderIdValue:(int32_t)value_;




- (NSNumber*)primitiveLastModified;
- (void)setPrimitiveLastModified:(NSNumber*)value;

- (int32_t)primitiveLastModifiedValue;
- (void)setPrimitiveLastModifiedValue:(int32_t)value_;




- (NSString*)primitiveLink;
- (void)setPrimitiveLink:(NSString*)value;




- (NSNumber*)primitiveMyId;
- (void)setPrimitiveMyId:(NSNumber*)value;

- (int32_t)primitiveMyIdValue;
- (void)setPrimitiveMyIdValue:(int32_t)value_;




- (NSNumber*)primitivePreferWeb;
- (void)setPrimitivePreferWeb:(NSNumber*)value;

- (BOOL)primitivePreferWebValue;
- (void)setPrimitivePreferWebValue:(BOOL)value_;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSNumber*)primitiveUnreadCount;
- (void)setPrimitiveUnreadCount:(NSNumber*)value;

- (int32_t)primitiveUnreadCountValue;
- (void)setPrimitiveUnreadCountValue:(int32_t)value_;




- (NSString*)primitiveUrl;
- (void)setPrimitiveUrl:(NSString*)value;




- (NSNumber*)primitiveUseReader;
- (void)setPrimitiveUseReader:(NSNumber*)value;

- (BOOL)primitiveUseReaderValue;
- (void)setPrimitiveUseReaderValue:(BOOL)value_;




@end
