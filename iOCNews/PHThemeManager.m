//
//  PHThemeManager.m
//  iOCNews
//
//  Created by Peter Hedlund on 10/29/17.
//  Copyright © 2017 Peter Hedlund. All rights reserved.
//

#import "PHThemeManager.h"
#import "UIColor+PHColor.h"

@implementation PHThemeManager

#define kPHBackgroundColorArray        @[kPHWhiteBackgroundColor, kPHSepiaBackgroundColor, kPHNightBackgroundColor]
#define kPHCellBackgroundColorArray    @[kPHWhiteCellBackgroundColor, kPHSepiaCellBackgroundColor, kPHNightCellBackgroundColor]
#define kPHIconColorArray              @[kPHWhiteIconColor, kPHSepiaIconColor, kPHNightIconColor]
#define kPHTextColorArray              @[kPHWhiteTextColor, kPHSepiaTextColor, kPHNightTextColor]
#define kPHLinkColorArray              @[kPHWhiteLinkColor, kPHSepiaLinkColor, kPHNightLinkColor]
#define kPHPopoverBackgroundColorArray @[kPHWhitePopoverBackgroundColor, kPHSepiaPopoverBackgroundColor, kPHNightPopoverBackgroundColor]
#define kPHPopoverButtonColorArray     @[kPHWhitePopoverButtonColor, kPHSepiaPopoverButtonColor, kPHNightPopoverButtonColor]
#define kPHPopoverBorderColorArray     @[kPHWhitePopoverBorderColor, kPHSepiaPopoverBorderColor, kPHNightPopoverBorderColor]

+ (PHThemeManager*)sharedManager {
    static dispatch_once_t once_token;
    static id sharedManager;
    dispatch_once(&once_token, ^{
        sharedManager = [[PHThemeManager alloc] init];
        [sharedManager setCurrentTheme:PHThemeDefault];
    });
    return sharedManager;
}

- (PHTheme)currentTheme {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
}

- (void)setCurrentTheme:(PHTheme)currentTheme {
    [[NSUserDefaults standardUserDefaults] setInteger:currentTheme forKey:@"CurrentTheme"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[[[UIApplication sharedApplication] delegate] window] setTintColor:[kPHIconColorArray objectAtIndex:self.currentTheme]];
    [UINavigationBar appearance].barTintColor = [UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1.0];
    
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[UIAlertController class]]] setTintColor:[UINavigationBar appearance].tintColor];

}

@end
