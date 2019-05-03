//
//  SummaryHelper.m
//  iOCNews
//
//  Created by Peter Hedlund on 9/3/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

#import "SummaryHelper.h"
#import <BRYHTMLParser/BRYHTMLParser.h>
#import "readable.h"

@implementation SummaryHelper

+ (nullable NSString *)readble:(NSString *)html url:(NSURL *)url {
    char *article;
    article = readable([html cStringUsingEncoding:NSUTF8StringEncoding],
                       [url.absoluteString cStringUsingEncoding:NSUTF8StringEncoding],
                       "UTF-8",
                       READABLE_OPTIONS_DEFAULT);
    if (article == NULL) {
//        html = @"<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>";
//        html = [html stringByAppendingString:self.item.body];
        return nil;
    } else {
        html = [NSString stringWithCString:article encoding:NSUTF8StringEncoding];
        html = [SummaryHelper fixRelativeUrl:html baseUrlString:[NSString stringWithFormat:@"%@://%@/%@", url.scheme, url.host, url.path]];
        return html;
    }
}

+ (NSString *) fixRelativeUrl:(NSString *)htmlString baseUrlString:(NSString*)base {
    __block NSString *result = [htmlString copy];
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:htmlString error:&error];
    
    if (error) {
        return result;
    }
    
    //parse body
    id<HTMLNode> bodyNode = [parser body];
    
    NSArray *inputNodes = [bodyNode findChildTags:@"img"];
    [inputNodes enumerateObjectsUsingBlock:^(id<HTMLNode> inputNode, NSUInteger idx, BOOL *stop) {
        if (inputNode) {
            NSString *src = [inputNode getAttributeNamed:@"src"];
            if (src != nil) {
                NSURL *url = [NSURL URLWithString:src relativeToURL:[NSURL URLWithString:base]];
                if (url != nil) {
                    NSString *newSrc = [url absoluteString];
                    result = [result stringByReplacingOccurrencesOfString:src withString:newSrc];
                }
            }
        }
    }];
    
    inputNodes = [bodyNode findChildTags:@"a"];
    [inputNodes enumerateObjectsUsingBlock:^(id<HTMLNode> inputNode, NSUInteger idx, BOOL *stop) {
        if (inputNode) {
            NSString *src = [inputNode getAttributeNamed:@"href"];
            if (src != nil) {
                NSURL *url = [NSURL URLWithString:src relativeToURL:[NSURL URLWithString:base]];
                if (url != nil) {
                    NSString *newSrc = [url absoluteString];
                    result = [result stringByReplacingOccurrencesOfString:src withString:newSrc];
                }
                
            }
        }
    }];
    
    return result;
}

+ (NSString *)createYoutubeItem:(NSString *)body andLink:(NSString *)link {
    __block NSString *result = body;
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:body error:&error];
    
    if (error) {
        return body;
    }
    
    //parse body
    id<HTMLNode> bodyNode = [parser body];
    
    NSArray *inputNodes = [bodyNode findChildTags:@"iframe"];
    [inputNodes enumerateObjectsUsingBlock:^(id<HTMLNode> inputNode, NSUInteger idx, BOOL *stop) {
        if (inputNode) {
            NSString *videoID = [SummaryHelper extractYoutubeVideoID:link];
            if (videoID) {
                CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
                NSInteger margin =[[NSUserDefaults standardUserDefaults] integerForKey:@"MarginPortrait"];
                double currentWidth = (screenSize.width / [UIScreen mainScreen].scale) * ((double)margin / 100);
                double newheight = currentWidth * 0.5625;
                NSString *embed = [NSString stringWithFormat:@"<embed id=\"yt\" src=\"http://www.youtube.com/embed/%@?playsinline=1\" type=\"text/html\" frameborder=\"0\" width=\"%ldpx\" height=\"%ldpdx\"></embed>", videoID, (long)currentWidth, (long)newheight];
                result = [result stringByReplacingOccurrencesOfString:[inputNode rawContents] withString:embed];
            }
        }
    }];
    return result;
}

+ (NSString*)replaceYTIframe:(NSString *)html {
    __block NSString *result = html;
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&error];
    
    if (error) {
        return html;
    }
    
    //parse body
    id<HTMLNode> bodyNode = [parser body];
    
    NSArray *inputNodes = [bodyNode findChildTags:@"iframe"];
    [inputNodes enumerateObjectsUsingBlock:^(id<HTMLNode> inputNode, NSUInteger idx, BOOL *stop) {
        if (inputNode) {
            NSString *src = [inputNode getAttributeNamed:@"src"];
            if (src && [src rangeOfString:@"youtu"].location != NSNotFound) {
                NSString *videoID = [SummaryHelper extractYoutubeVideoID:src];
                if (videoID) {
                    CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
                    NSInteger margin =[[NSUserDefaults standardUserDefaults] integerForKey:@"MarginPortrait"];
                    double currentWidth = (screenSize.width / [UIScreen mainScreen].scale) * ((double)margin / 100);
                    double newheight = currentWidth * 0.5625;
                    NSString *embed = [NSString stringWithFormat:@"<embed id=\"yt\" src=\"http://www.youtube.com/embed/%@?playsinline=1\" type=\"text/html\" frameborder=\"0\" width=\"%ldpx\" height=\"%ldpdx\"></embed>", videoID, (long)currentWidth, (long)newheight];
                    result = [result stringByReplacingOccurrencesOfString:[inputNode rawContents] withString:embed];
                }
            }
            if (src && [src rangeOfString:@"vimeo"].location != NSNotFound) {
                NSString *videoID = [SummaryHelper extractVimeoVideoID:src];
                if (videoID) {
                    CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
                    NSInteger margin =[[NSUserDefaults standardUserDefaults] integerForKey:@"MarginPortrait"];
                    double currentWidth = (screenSize.width / [UIScreen mainScreen].scale) * ((double)margin / 100);
                    double newheight = currentWidth * 0.5625;
                    NSString *embed = [NSString stringWithFormat:@"<iframe id=\"vimeo\" src=\"http://player.vimeo.com/video/%@\" type=\"text/html\" frameborder=\"0\" width=\"%ldpx\" height=\"%ldpdx\"></iframe>", videoID, (long)currentWidth, (long)newheight];
                    result = [result stringByReplacingOccurrencesOfString:[inputNode rawContents] withString:embed];
                }
            }
        }
    }];
    
    return result;
}

//based on https://gist.github.com/rais38/4683817
/**
 @see https://devforums.apple.com/message/705665#705665
 extractYoutubeVideoID: works for the following URL formats:
 www.youtube.com/v/VIDEOID
 www.youtube.com?v=VIDEOID
 www.youtube.com/watch?v=WHsHKzYOV2E&feature=youtu.be
 www.youtube.com/watch?v=WHsHKzYOV2E
 youtu.be/KFPtWedl7wg_U923
 www.youtube.com/watch?feature=player_detailpage&v=WHsHKzYOV2E#t=31s
 youtube.googleapis.com/v/WHsHKzYOV2E
 www.youtube.com/embed/VIDEOID
 */

+ (NSString *)extractYoutubeVideoID:(NSString *)urlYoutube {
    NSString *regexString = @"(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)|(?<=embed/)([-a-zA-Z0-9_]+)";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:urlYoutube options:0 range:NSMakeRange(0, [urlYoutube length])];
    if(!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
        NSString *substringForFirstMatch = [urlYoutube substringWithRange:rangeOfFirstMatch];
        return substringForFirstMatch;
    }
    
    return nil;
}

//based on http://stackoverflow.com/a/16841070/2036378
+ (NSString *)extractVimeoVideoID:(NSString *)urlVimeo {
    NSString *regexString = @"([0-9]{2,11})"; // @"(https?://)?(www.)?(player.)?vimeo.com/([a-z]*/)*([0-9]{6,11})[?]?.*";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:urlVimeo options:0 range:NSMakeRange(0, [urlVimeo length])];
    if(!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
        NSString *substringForFirstMatch = [urlVimeo substringWithRange:rangeOfFirstMatch];
        return substringForFirstMatch;
    }
    
    return nil;
}

@end
