//
//  SummaryHelper.h
//  iOCNews
//
//  Created by Peter Hedlund on 9/3/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Item+CoreDataClass.h"

@interface SummaryHelper : NSObject

+ (NSString *)fixRelativeUrl:(NSString *)htmlString baseUrlString:(NSString*)base;
+ (NSString *)createYoutubeItem:(Item *)item;
+ (NSString *)extractYoutubeVideoID:(NSString *)urlYoutube;
+ (NSString *)replaceYTIframe:(NSString *)html;
+ (NSString *)extractVimeoVideoID:(NSString *)urlVimeo;
+ (nullable NSString *)readble:(NSString *)html url:(NSURL *)url;

@end
