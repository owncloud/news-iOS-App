//
//  PHThemeManager.h
//  iOCNews
//
//  Created by Peter Hedlund on 10/29/17.
//  Copyright © 2017 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PHTheme) {
    PHThemeDefault = 0,
    PHThemeSepia = 1,
    PHThemeNight = 2
};


@interface UILabel (ThemeColor)

- (void)setThemeTextColor:(UIColor *)themeTextColor UI_APPEARANCE_SELECTOR;

@end

@interface PHThemeManager : NSObject

+ (PHThemeManager *)sharedManager;

@property(assign) PHTheme currentTheme;
@property(strong, readonly) UIColor *unreadTextColor;
@property(strong, readonly) UIColor *readTextColor;
@property(strong, readonly) NSString *themeName;

@property(strong, readonly) NSString *backgroundHex;
@property(strong, readonly) NSString *textHex;
@property(strong, readonly) NSString *linkHex;
@property(strong, readonly) NSString *footerLinkHex;

- (void)applyCurrentTheme;

@end
