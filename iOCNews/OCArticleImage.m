//
//  OCArticleImage.m
//  iOCNews
//
//  Created by Peter Hedlund on 6/30/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "OCArticleImage.h"
#import "HTMLParser.h"

@implementation OCArticleImage

+ (NSString *) findImage:(NSString *)htmlString {
    __block NSString *result = nil;
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:htmlString error:&error];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return result;
    }
    
    //parse body
    HTMLNode *bodyNode = [parser body];
    
    NSArray *inputNodes = [bodyNode findChildTags:@"img"];
    [inputNodes enumerateObjectsUsingBlock:^(HTMLNode *inputNode, NSUInteger idx, BOOL *stop) {
        if (inputNode) {
            result = [inputNode getAttributeNamed:@"src"];
            
            [[OCArticleImage imagesToSkip] enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
                if ([result rangeOfString:name].location != NSNotFound) {
                    result = nil;
                    *stop = YES;
                }
            }];
            NSString *height = [inputNode getAttributeNamed:@"height"];
            if ([height isEqualToString:@"1"]) {
                result = nil;
            }
            if (result != nil) {
                *stop = YES;
            }
        }
    }];
    
    return [result stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
}

+ (NSArray*)imagesToSkip {
    return @[
             @"feedads",
             @"twitter_icon",
             @"facebook_icon",
             @"feedburner",
             @"gplus-16"
             ];
}

@end
