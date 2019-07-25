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

+ (NSString *_Nonnull)fixRelativeUrl:(NSString *_Nonnull)htmlString baseUrlString:(NSString*_Nonnull)base;
+ (NSString *_Nonnull)createYoutubeItem:(NSString *_Nonnull)body andLink:(NSString *_Nonnull)link;
+ (NSString *_Nonnull)extractYoutubeVideoID:(NSString *_Nonnull)urlYoutube;
+ (NSString *_Nonnull)replaceYTIframe:(NSString *_Nonnull)html;
+ (NSString *_Nonnull)extractVimeoVideoID:(NSString *_Nonnull)urlVimeo;
+ (nullable NSString *)readble:(NSString *_Nonnull)html url:(NSURL *_Nonnull)url;

@end
