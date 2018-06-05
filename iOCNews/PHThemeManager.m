//
//  PHThemeManager.m
//  iOCNews
//
//  Created by Peter Hedlund on 10/29/17.
//  Copyright © 2017 Peter Hedlund. All rights reserved.
//

#import "PHThemeManager.h"
#import "UIColor+PHColor.h"
#import "OCFeedListController.h"
#import "OCFeedCell.h"
#import "OCArticleCell.h"
#import "PHArticleManagerController.h"

@implementation UILabel (ThemeColor)

- (void)setThemeTextColor:(UIColor *)themeTextColor {
    if (themeTextColor) {
        self.textColor = themeTextColor;
    }
}

@end

@implementation PHThemeManager

#define kPHBackgroundColorArray        @[kPHWhiteBackgroundColor, kPHSepiaBackgroundColor, kPHNightBackgroundColor]
#define kPHCellBackgroundColorArray    @[kPHWhiteCellBackgroundColor, kPHSepiaCellBackgroundColor, kPHNightCellBackgroundColor]
#define kPHIconColorArray              @[kPHWhiteIconColor, kPHSepiaIconColor, kPHNightIconColor]
#define kPHTextColorArray              @[kPHWhiteTextColor, kPHSepiaTextColor, kPHNightTextColor]
#define kPHLinkColorArray              @[kPHWhiteLinkColor, kPHSepiaLinkColor, kPHNightLinkColor]
#define kPHPopoverBackgroundColorArray @[kPHWhitePopoverBackgroundColor, kPHSepiaPopoverBackgroundColor, kPHNightPopoverBackgroundColor]
#define kPHPopoverButtonColorArray     @[kPHWhitePopoverButtonColor, kPHSepiaPopoverButtonColor, kPHNightPopoverButtonColor]
#define kPHPopoverBorderColorArray     @[kPHWhitePopoverBorderColor, kPHSepiaPopoverBorderColor, kPHNightPopoverBorderColor]

#define kPHUnreadTextColorArray        @[[UIColor darkTextColor], [UIColor darkTextColor], [UIColor lightTextColor]]
#define kPHReadTextColorArray          @[[UIColor colorWithWhite:0.0 alpha:0.40], [UIColor colorWithWhite:0.41 alpha:1.0], [UIColor colorWithWhite:0.41 alpha:1.0]]

#define kPHSwitchTintColorArray        @[kPHWhitePopoverBorderColor, kPHSepiaPopoverBorderColor, kPHNightIconColor]

+ (PHThemeManager*)sharedManager {
    static dispatch_once_t once_token;
    static id sharedManager;
    dispatch_once(&once_token, ^{
        sharedManager = [[PHThemeManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        [self applyCurrentTheme];
    }
    return self;
}

- (PHTheme)currentTheme {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
}

- (void)setCurrentTheme:(PHTheme)currentTheme {
    [[NSUserDefaults standardUserDefaults] setInteger:currentTheme forKey:@"CurrentTheme"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[[[UIApplication sharedApplication] delegate] window] setTintColor:[kPHIconColorArray objectAtIndex:currentTheme]];
    
    [UINavigationBar appearance].barTintColor = [kPHPopoverButtonColorArray objectAtIndex:currentTheme];
    NSMutableDictionary<NSAttributedStringKey, id> *newTitleAttributes = [NSMutableDictionary<NSAttributedStringKey, id> new];
    newTitleAttributes[NSForegroundColorAttributeName] = [kPHUnreadTextColorArray objectAtIndex:currentTheme];
    [UINavigationBar appearance].titleTextAttributes = newTitleAttributes;
    [UINavigationBar appearance].tintColor = [kPHIconColorArray objectAtIndex:currentTheme];

    [UIBarButtonItem appearance].tintColor = [kPHUnreadTextColorArray objectAtIndex:currentTheme];

    [UITableViewCell appearance].backgroundColor = [kPHCellBackgroundColorArray objectAtIndex:currentTheme];

    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[UIAlertController class]]] setTintColor:[UINavigationBar appearance].tintColor];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[OCArticleCell class]]] setBackgroundColor:[kPHCellBackgroundColorArray objectAtIndex:currentTheme]];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[OCArticleListController class]]] setBackgroundColor:[kPHCellBackgroundColorArray objectAtIndex:currentTheme]];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[OCFeedCell class]]] setBackgroundColor:[kPHPopoverBackgroundColorArray objectAtIndex:currentTheme]];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[OCFeedListController class]]] setBackgroundColor:[kPHPopoverBackgroundColorArray objectAtIndex:currentTheme]];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[OCWebController class]]] setBackgroundColor:[UIColor clearColor]];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[WKWebView class]]] setBackgroundColor:[UIColor clearColor]];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[UITableViewHeaderFooterView class]]] setBackgroundColor:[kPHPopoverButtonColorArray objectAtIndex:currentTheme]];

    [[UITableView appearanceWhenContainedInInstancesOfClasses:@[[OCArticleListController class]]] setBackgroundColor:[kPHCellBackgroundColorArray objectAtIndex:currentTheme]];
    [[UITableView appearanceWhenContainedInInstancesOfClasses:@[[OCFeedListController class]]] setBackgroundColor:[kPHPopoverBackgroundColorArray objectAtIndex:currentTheme]];

    [UIScrollView appearance].backgroundColor = [kPHCellBackgroundColorArray objectAtIndex:currentTheme];
    [UIScrollView appearanceWhenContainedInInstancesOfClasses:@[[OCFeedListController class]]].backgroundColor = [kPHPopoverBackgroundColorArray objectAtIndex:currentTheme];

    [[UILabel appearance] setThemeTextColor:[kPHTextColorArray objectAtIndex:currentTheme]];

    [[UISwitch appearance] setOnTintColor:[kPHSwitchTintColorArray objectAtIndex:currentTheme]];
    [[UISwitch appearance] setTintColor:[kPHSwitchTintColorArray objectAtIndex:currentTheme]];

    [WKWebView appearance].backgroundColor = [kPHCellBackgroundColorArray objectAtIndex:currentTheme];

    _unreadTextColor = [kPHUnreadTextColorArray objectAtIndex:currentTheme];
    _readTextColor = [kPHReadTextColorArray objectAtIndex:currentTheme];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITextField class]]] setThemeTextColor:_readTextColor];
    [[UITextField appearance] setTextColor:_unreadTextColor];
    [[UITextView appearance] setTextColor:_unreadTextColor];
    [[UIStepper appearance] setTintColor:_unreadTextColor];

    NSArray * windows = [UIApplication sharedApplication].windows;
    
    for (UIWindow *window in windows) {
        for (UIView *view in window.subviews) {
            [view removeFromSuperview];
            [window addSubview:view];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ThemeUpdate" object:self];
    
}

- (void)applyCurrentTheme {
    PHTheme current = self.currentTheme;
    [self setCurrentTheme:current];
}

- (NSString *)themeName {
    switch (self.currentTheme) {
        case PHThemeDefault:
            return NSLocalizedString(@"Default", @"Name of the defualt theme");
            break;
        case PHThemeSepia:
            return NSLocalizedString(@"Sepia", @"Name of the sepia theme");
            break;
        case PHThemeNight:
            return NSLocalizedString(@"Night", @"Name of the night theme");
            break;
        default:
            return @"Default";
            break;
    }
}

@end
