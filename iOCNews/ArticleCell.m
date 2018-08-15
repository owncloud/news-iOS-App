//
//  ArticleCell.m
//  iOCNews
//
//  Created by Peter Hedlund on 7/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

#import "ArticleCell.h"
#import "Feed.h"
#import "OCNewsHelper.h"
#import "OCAPIClient.h"
#import "readable.h"
#import <BRYHTMLParser/BRYHTMLParser.h>

@interface ArticleCell ()

- (void)configureView;
- (void) writeAndLoadHtml:(NSString*)html feed:(Feed *)feed;
- (NSString *)replaceYTIframe:(NSString *)html;
- (NSString *)extractYoutubeVideoID:(NSString *)urlYoutube;

@property (strong, nonatomic) WKWebViewConfiguration *webConfig;

@end

@implementation ArticleCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (WKWebViewConfiguration *)webConfig {
    if (!_webConfig) {
        _webConfig = [WKWebViewConfiguration new];
        _webConfig.allowsInlineMediaPlayback = YES;
        _webConfig.requiresUserActionForMediaPlayback = YES;
    }
    return _webConfig;
}

- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:self.webConfig];
        _webView.customUserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1";
        _webView.opaque = NO;
        _webView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_webView];
        
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_webView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_webView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    }
    return _webView;
}

- (void)prepareForReuse {
//    self.item = nil;
    [self.webView removeFromSuperview];
    self.webView.navigationDelegate = nil;
    self.webView.UIDelegate = nil;
    self.webView = nil;
}

- (void)setItem:(Item *)item {
    _item = item;
    [self configureView];
}

- (void)configureView
{
    @try {
        if (_item) {
            Feed *feed = [[OCNewsHelper sharedHelper] feedWithId:self.item.feedId];
            
            if (feed.preferWebValue) {
                if (feed.useReaderValue) {
                    if (self.item.readable) {
                        [self writeAndLoadHtml:self.item.readable feed:feed];
                    } else {
                        [OCAPIClient sharedClient].requestSerializer = [OCAPIClient httpRequestSerializer];
                        [[OCAPIClient sharedClient] GET:self.item.url parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                            NSString *html;
                            if (responseObject) {
                                html = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                                char *article;
                                article = readable([html cStringUsingEncoding:NSUTF8StringEncoding],
                                                   [[[task.response URL] absoluteString] cStringUsingEncoding:NSUTF8StringEncoding],
                                                   "UTF-8",
                                                   READABLE_OPTIONS_DEFAULT);
                                if (article == NULL) {
                                    html = @"<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>";
                                    html = [html stringByAppendingString:self.item.body];
                                } else {
                                    html = [NSString stringWithCString:article encoding:NSUTF8StringEncoding];
                                    html = [self fixRelativeUrl:html
                                                  baseUrlString:[NSString stringWithFormat:@"%@://%@/%@", [[task.response URL] scheme], [[task.response URL] host], [[task.response URL] path]]];
                                }
                                self.item.readable = html;
                                [[OCNewsHelper sharedHelper] saveContext];
                            } else {
                                html = @"<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>";
                                html = [html stringByAppendingString:self.item.body];
                            }
                            [self writeAndLoadHtml:html feed:feed];
                            
                        } failure:^(NSURLSessionDataTask *task, NSError *error) {
                            NSString *html = @"<p style='color: #CC6600;'><i>(There was an error downloading the article. Showing summary instead.)</i></p>";
                            if (self.item.body != nil) {
                                html = [html stringByAppendingString:self.item.body];
                            }
                            [self writeAndLoadHtml:html feed:feed];
                        }];
                    }
                } else {
                    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.item.url]]];
                }
            } else {
                NSString *html = self.item.body;
                NSURL *itemURL = [NSURL URLWithString:self.item.url];
                NSString *baseString = [NSString stringWithFormat:@"%@://%@", [itemURL scheme], [itemURL host]];
                if ([baseString rangeOfString:@"youtu"].location != NSNotFound) {
                    if ([html rangeOfString:@"iframe"].location != NSNotFound) {
                        html = [self createYoutubeItem:self.item];
                    }
                }
                html = [self fixRelativeUrl:html baseUrlString:baseString];
                [self writeAndLoadHtml:html feed:feed];
            }
        }
        
    }
    @catch (NSException *exception) {
        //
    }
    @finally {
        //
    }
}

- (void)writeAndLoadHtml:(NSString *)html feed:(Feed *)feed {
    html = [self replaceYTIframe:html];
    NSURL *source = [[NSBundle mainBundle] URLForResource:@"rss" withExtension:@"html" subdirectory:nil];
    NSString *objectHtml = [NSString stringWithContentsOfURL:source encoding:NSUTF8StringEncoding error:nil];
    
    NSString *dateText = @"";
    NSNumber *dateNumber = self.item.pubDate;
    if (![dateNumber isKindOfClass:[NSNull class]]) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dateNumber doubleValue]];
        if (date) {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            dateFormat.dateStyle = NSDateFormatterMediumStyle;
            dateFormat.timeStyle = NSDateFormatterShortStyle;
            dateText = [dateText stringByAppendingString:[dateFormat stringFromDate:date]];
        }
    }
    
    if (feed && feed.title) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$FeedTitle$" withString:feed.title];
    }
    if (dateText) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleDate$" withString:dateText];
    }
    if (self.item.title) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleTitle$" withString:self.item.title];
    }
    if (self.item.url) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleLink$" withString:self.item.url];
    }
    NSString *author = self.item.author;
    if (![author isKindOfClass:[NSNull class]]) {
        if (author.length > 0) {
            author = [NSString stringWithFormat:@"By %@", author];
        }
    } else {
        author = @"";
    }
    if (author) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleAuthor$" withString:author];
    }
    if (html) {
        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$ArticleSummary$" withString:html];
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    NSURL *objectSaveURL = [docDir  URLByAppendingPathComponent:@"summary.html"];
    [objectHtml writeToURL:objectSaveURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadFileURL:objectSaveURL allowingReadAccessToURL:docDir];
}

- (NSString *) fixRelativeUrl:(NSString *)htmlString baseUrlString:(NSString*)base {
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

- (NSString *)createYoutubeItem:(Item *)item {
    __block NSString *result = item.body;
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:item.body error:&error];
    
    if (error) {
        return item.body;
    }
    
    //parse body
    id<HTMLNode> bodyNode = [parser body];
    
    NSArray *inputNodes = [bodyNode findChildTags:@"iframe"];
    [inputNodes enumerateObjectsUsingBlock:^(id<HTMLNode> inputNode, NSUInteger idx, BOOL *stop) {
        if (inputNode) {
            NSString *videoID = [self extractYoutubeVideoID:item.url];
            if (videoID) {
                NSString *height = [inputNode getAttributeNamed:@"height"];
                NSString *width = [inputNode getAttributeNamed:@"width"];
                NSString *heightString = @"";
                NSString *widthString = @"";
                if (height.length > 0) {
                    heightString = [NSString stringWithFormat:@"height=\"%@\"", height];
                }
                if (width.length > 0) {
                    widthString = [NSString stringWithFormat:@"width=\"%@\"", width];
                }
                NSString *embed = [NSString stringWithFormat:@"<embed class=\"yt\" src=\"http://www.youtube.com/embed/%@?playsinline=1\" type=\"text/html\" frameborder=\"0\" %@ %@></embed>", videoID, heightString, widthString];
                result = [result stringByReplacingOccurrencesOfString:[inputNode rawContents] withString:embed];
            }
        }
    }];
    return result;
}

- (NSString*)replaceYTIframe:(NSString *)html {
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
                NSString *videoID = [self extractYoutubeVideoID:src];
                if (videoID) {
                    NSString *height = [inputNode getAttributeNamed:@"height"];
                    NSString *width = [inputNode getAttributeNamed:@"width"];
                    NSString *heightString = @"";
                    NSString *widthString = @"";
                    if (height.length > 0) {
                        heightString = [NSString stringWithFormat:@"height=\"%@\"", height];
                    }
                    if (width.length > 0) {
                        widthString = [NSString stringWithFormat:@"width=\"%@\"", width];
                    }
                    NSString *embed = [NSString stringWithFormat:@"<embed id=\"yt\" src=\"http://www.youtube.com/embed/%@?playsinline=1\" type=\"text/html\" frameborder=\"0\" %@ %@></embed>", videoID, heightString, widthString];
                    result = [result stringByReplacingOccurrencesOfString:[inputNode rawContents] withString:embed];
                }
            }
            if (src && [src rangeOfString:@"vimeo"].location != NSNotFound) {
                NSString *videoID = [self extractVimeoVideoID:src];
                if (videoID) {
                    NSString *height = [inputNode getAttributeNamed:@"height"];
                    NSString *width = [inputNode getAttributeNamed:@"width"];
                    NSString *heightString = @"";
                    NSString *widthString = @"";
                    if (height.length > 0) {
                        heightString = [NSString stringWithFormat:@"height=\"%@\"", height];
                    }
                    if (width.length > 0) {
                        widthString = [NSString stringWithFormat:@"width=\"%@\"", width];
                    }
                    NSString *embed = [NSString stringWithFormat:@"<iframe id=\"vimeo\" src=\"http://player.vimeo.com/video/%@\" type=\"text/html\" frameborder=\"0\" %@ %@></iframe>", videoID, heightString, widthString];
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

- (NSString *)extractYoutubeVideoID:(NSString *)urlYoutube {
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
- (NSString *)extractVimeoVideoID:(NSString *)urlVimeo {
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
