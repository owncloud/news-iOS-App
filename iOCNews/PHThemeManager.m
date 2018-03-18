//
//  PHThemeManager.m
//  iOCNews
//
//  Created by Peter Hedlund on 10/29/17.
//  Copyright © 2017 Peter Hedlund. All rights reserved.
//

#import "PHThemeManager.h"
#import "UIColor+PHColor.h"
#import "ThemeView.h"

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

- (instancetype)init {
    if (self = [super init]) {
        PHTheme current = self.currentTheme;
        [self setCurrentTheme:current];
    }
    return self;
}


- (PHTheme)currentTheme {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
}

- (void)setCurrentTheme:(PHTheme)currentTheme {
    [[NSUserDefaults standardUserDefaults] setInteger:currentTheme forKey:@"CurrentTheme"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[[[UIApplication sharedApplication] delegate] window] setTintColor:[kPHIconColorArray objectAtIndex:self.currentTheme]];
    [UINavigationBar appearance].barTintColor = [kPHPopoverButtonColorArray objectAtIndex:self.currentTheme];
    NSMutableDictionary<NSAttributedStringKey, id> *newTitleAttributes = [NSMutableDictionary<NSAttributedStringKey, id> new];
    newTitleAttributes[NSForegroundColorAttributeName] = [kPHIconColorArray objectAtIndex:self.currentTheme];
    [UINavigationBar appearance].titleTextAttributes = newTitleAttributes;
    [UINavigationBar appearance].tintColor = [kPHIconColorArray objectAtIndex:self.currentTheme];

    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[UIAlertController class]]] setTintColor:[UINavigationBar appearance].tintColor];
    [UIScrollView appearance].backgroundColor = [kPHCellBackgroundColorArray objectAtIndex:self.currentTheme];
    [UITableViewCell appearance].backgroundColor = [kPHCellBackgroundColorArray objectAtIndex:self.currentTheme];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class]]] setBackgroundColor:[kPHCellBackgroundColorArray objectAtIndex:self.currentTheme]];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[UITableView class]]] setBackgroundColor:[kPHCellBackgroundColorArray objectAtIndex:self.currentTheme]];
    [ThemeView appearance].backgroundColor = [kPHCellBackgroundColorArray objectAtIndex:self.currentTheme];
    
    NSArray * windows = [UIApplication sharedApplication].windows;
    
    for (UIWindow *window in windows) {
        for (UIView *view in window.subviews) {
            [view removeFromSuperview];
            [window addSubview:view];
        }
    }
}

@end
