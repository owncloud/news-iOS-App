//
//  OCArticleImage.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2013 Peter Hedlund peter.hedlund@me.com
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 *************************************************************************/

#import "OCArticleImage.h"
#import <BRYHTMLParser/BRYHTMLParser.h>

@implementation OCArticleImage

+ (NSString *) findImage:(NSString *)htmlString {
    __block NSString *result = nil;
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:htmlString error:&error];
    
    if (error) {
//        NSLog(@"Error: %@", error);
        return result;
    }
    
    //parse body
    id<HTMLNode> bodyNode = [parser body];
    
    NSArray *inputNodes = [bodyNode findChildTags:@"img"];
    [inputNodes enumerateObjectsUsingBlock:^(id<HTMLNode> inputNode, NSUInteger idx, BOOL *stop) {
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
