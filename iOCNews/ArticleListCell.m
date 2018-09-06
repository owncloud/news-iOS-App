//
//  ArticleCell.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2012-2016 Peter Hedlund peter.hedlund@me.com
 
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

#import "ArticleListCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+PHColor.h"
#import "NSString+HTML.h"
#import "OCNewsHelper.h"
#import "Feed+CoreDataClass.h"
#import "PHThemeManager.h"
#import "OCArticleImage.h"
#import "UIImageView+OCWebCache.h"

@implementation ArticleListCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.selectedBackgroundView = [UIView new];
        [self.selectedBackgroundView setBackgroundColor:[UIColor cellBackgroundColor]];
        
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.frame = CGRectMake(0.0f, 153.0f, 10000.0, 0.5f);
        bottomBorder.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
        [self.contentView.layer addSublayer:bottomBorder];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    [super setSelected:selected animated:animated];

    self.mainView.backgroundColor = [UIColor cellBackgroundColor];
    self.mainSubView.backgroundColor = [UIColor cellBackgroundColor];
    self.contentContainerView.backgroundColor = [UIColor cellBackgroundColor];
    self.thumbnailContainerView.backgroundColor = [UIColor cellBackgroundColor];
    self.starContainerView.backgroundColor = [UIColor cellBackgroundColor];
    self.articleImage.backgroundColor = [UIColor cellBackgroundColor];
    self.starImage.backgroundColor = [UIColor cellBackgroundColor];
    self.favIconImage.backgroundColor = [UIColor cellBackgroundColor];
    self.titleLabel.backgroundColor = [UIColor cellBackgroundColor];
    self.dateLabel.backgroundColor = [UIColor cellBackgroundColor];
    self.summaryLabel.backgroundColor = [UIColor cellBackgroundColor];
}

//- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
//    [super setHighlighted:highlighted animated:animated];
//    if (highlighted) {
//        [self.contentView setBackgroundColor: [UIColor cellSelectionColor]];
//    } else {
//        [self.contentView setBackgroundColor: [UIColor clearColor]];
//    }
//}
//

//- (void)prepareForReuse {
//    self.articleImage.image = nil;
//    self.articleImage.hidden = NO;
//    self.thumbnailContainerWidthConstraint.constant = self.articleImage.frame.size.width;
//    self.articleImageWidthConstraint.constant = self.articleImage.frame.size.width;
//    self.contentContainerLeadingConstraint.constant = self.articleImage.frame.size.width;
//}

- (void)layoutSubviews {
    if (self.item) {
        if (self.item.imageLink) {
            self.articleImage.hidden = NO;
            self.thumbnailContainerWidthConstraint.constant = self.articleImage.frame.size.width;
            self.articleImageWidthConstraint.constant = self.articleImage.frame.size.width;
            self.contentContainerLeadingConstraint.constant = self.articleImage.frame.size.width;
        } else {
            self.articleImage.hidden = YES;
            self.thumbnailContainerWidthConstraint.constant = 0.0;
            self.articleImageWidthConstraint.constant = 0.0;
            self.contentContainerLeadingConstraint.constant = 0.0;
        }
    }
    [super layoutSubviews];
}

- (void)setItem:(Item *)item {
    _item = item;
    [self configureView];
}

- (void)configureView {
    self.mainCellViewWidthContraint.constant = self.contentWidth;
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.dateLabel.font = [self makeItalic:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    self.summaryLabel.font = [self makeSmaller:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
    
    self.titleLabel.text = [_item.title stringByConvertingHTMLToPlainText];
    NSString *dateLabelText = @"";
    
    NSNumber *dateNumber = @(_item.pubDate);
    if (![dateNumber isKindOfClass:[NSNull class]]) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dateNumber doubleValue]];
        if (date) {
            NSLocale *currentLocale = [NSLocale currentLocale];
            NSString *dateComponents = @"MMM d";
            NSString *dateFormatString = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:currentLocale];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            dateFormat.dateFormat = dateFormatString;
            dateLabelText = [dateLabelText stringByAppendingString:[dateFormat stringFromDate:date]];
        }
    }
    if (dateLabelText.length > 0) {
        dateLabelText = [dateLabelText stringByAppendingString:@" | "];
    }
    
    NSString *author = _item.author;
    if (![author isKindOfClass:[NSNull class]]) {
        if (author.length > 0) {
            const int clipLength = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 50 : 25;
            if([author length] > clipLength) {
                dateLabelText = [dateLabelText stringByAppendingString:[NSString stringWithFormat:@"%@...",[author substringToIndex:clipLength]]];
            } else {
                dateLabelText = [dateLabelText stringByAppendingString:author];
            }
        }
    }
    Feed *feed = [[OCNewsHelper sharedHelper] feedWithId:_item.feedId];
    if (feed) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowFavicons"]) {
            //                if (cell.tag == indexPath.row) {
            [[OCNewsHelper sharedHelper] faviconForFeedWithId:feed.myId imageView: self.favIconImage];
            self.favIconImage.hidden = NO;
            self.dateLabelLeadingConstraint.constant = 21;
            //                }
        }
        else {
            self.favIconImage.hidden = YES;
            self.dateLabelLeadingConstraint.constant = 0.0;
        }
        
        if (feed.title && ![feed.title isEqualToString:author]) {
            if (author.length > 0) {
                dateLabelText = [dateLabelText stringByAppendingString:@" | "];
            }
            dateLabelText = [dateLabelText stringByAppendingString:feed.title];
        }
    }
    self.dateLabel.text = dateLabelText;
    
    NSString *summary = _item.body;
    if ([summary rangeOfString:@"<style>" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        if ([summary rangeOfString:@"</style>" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            NSRange r;
            r.location = [summary rangeOfString:@"<style>" options:NSCaseInsensitiveSearch].location;
            r.length = [summary rangeOfString:@"</style>" options:NSCaseInsensitiveSearch].location - r.location + 8;
            NSString *sub = [summary substringWithRange:r];
            summary = [summary stringByReplacingOccurrencesOfString:sub withString:@""];
        }
    }
    self.summaryLabel.text = [summary stringByConvertingHTMLToPlainText];
    self.starImage.image = nil;
    if (_item.starred) {
        self.starImage.image = [UIImage imageNamed:@"star_icon"];
    }
    if (_item.unread == YES) {
        [self.summaryLabel setThemeTextColor:PHThemeManager.sharedManager.unreadTextColor];
        [self.titleLabel setThemeTextColor:PHThemeManager.sharedManager.unreadTextColor];
        [self.dateLabel setThemeTextColor:PHThemeManager.sharedManager.unreadTextColor];
        self.articleImage.alpha = 1.0f;
        self.favIconImage.alpha = 1.0f;
    } else {
        [self.summaryLabel setThemeTextColor:[UIColor readTextColor]];
        [self.titleLabel setThemeTextColor:[UIColor readTextColor]];
        [self.dateLabel setThemeTextColor:[UIColor readTextColor]];
        self.articleImage.alpha = 0.4f;
        self.favIconImage.alpha = 0.4f;
    }
    self.summaryLabel.highlightedTextColor = self.summaryLabel.textColor;
    self.titleLabel.highlightedTextColor = self.titleLabel.textColor;
    self.dateLabel.highlightedTextColor = self.dateLabel.textColor;
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowThumbnails"]) {
//        NSString *urlString = [OCArticleImage findImage:summary];
//        if (urlString) {
//            //                if (self.tag == indexPath.row) {
//            //                    dispatch_main_async_safe(^{
//            self.articleImage.hidden = NO;
//            self.thumbnailContainerWidthConstraint.constant = self.articleImage.frame.size.width;
//            self.articleImageWidthConstraint.constant = self.articleImage.frame.size.width;
//            self.contentContainerLeadingConstraint.constant = self.articleImage.frame.size.width;
//            [self.articleImage setRoundedImageWithURL:[NSURL URLWithString:urlString]];
//            //                    });
//            //                }
//        } else {
//            self.articleImage.hidden = YES;
//            self.thumbnailContainerWidthConstraint.constant = 0.0;
//            self.articleImageWidthConstraint.constant = 0.0;
//            self.contentContainerLeadingConstraint.constant = 0.0;
//        }
//    } else {
//        self.articleImage.hidden = YES;
//        self.thumbnailContainerWidthConstraint.constant = 0.0;
//        self.articleImageWidthConstraint.constant = 0.0;
//        self.contentContainerLeadingConstraint.constant = 0.0;
//    }
    self.highlighted = NO;
//    [self setNeedsLayout];
}

- (UIFont*) makeItalic:(UIFont*)font {
    UIFontDescriptor *desc = font.fontDescriptor;
    UIFontDescriptor *italic = [desc fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    return [UIFont fontWithDescriptor:italic size:0.0f];
}

- (UIFont*) makeSmaller:(UIFont*)font {
    UIFontDescriptor *desc = font.fontDescriptor;
    UIFontDescriptor *italic = [desc fontDescriptorWithSize:desc.pointSize - 1];
    return [UIFont fontWithDescriptor:italic size:0.0f];
}

@end
