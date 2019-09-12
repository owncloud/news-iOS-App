//
//  PHThemeManager.m
//  iOCNews
//
//  Created by Peter Hedlund on 10/29/17.
//  Copyright © 2017 Peter Hedlund. All rights reserved.
//

@import WebKit;

#import "PHThemeManager.h"
#import "UIColor+PHColor.h"
#import "OCFeedListController.h"
#import "OCFeedCell.h"
#import "ArticleController.h"
#import "OCSettingsController.h"

@implementation UILabel (ThemeColor)

- (void)setThemeTextColor:(UIColor *)themeTextColor {
    if (themeTextColor) {
        self.textColor = themeTextColor;
    }
}

@end

@implementation PHThemeManager

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

    [[[[UIApplication sharedApplication] delegate] window] setTintColor:UIColor.ph_iconColor];
    
    [UINavigationBar appearance].barTintColor = UIColor.ph_popoverButtonColor;
    NSMutableDictionary<NSAttributedStringKey, id> *newTitleAttributes = [NSMutableDictionary<NSAttributedStringKey, id> new];
    newTitleAttributes[NSForegroundColorAttributeName] = UIColor.ph_textColor;
    [UINavigationBar appearance].titleTextAttributes = newTitleAttributes;
    [UINavigationBar appearance].tintColor = UIColor.ph_iconColor;

    [UIBarButtonItem appearance].tintColor = UIColor.ph_textColor;

    [UITableViewCell appearance].backgroundColor = UIColor.ph_cellBackgroundColor;

    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[UIAlertController class]]] setTintColor:[UINavigationBar appearance].tintColor];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[ArticleListController class]]] setBackgroundColor:UIColor.ph_cellBackgroundColor];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[OCFeedCell class]]] setBackgroundColor:UIColor.ph_popoverBackgroundColor];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[OCFeedListController class]]] setBackgroundColor:UIColor.ph_popoverBackgroundColor];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[UITableViewHeaderFooterView class]]] setBackgroundColor:UIColor.ph_popoverButtonColor];

    [[UICollectionView appearanceWhenContainedInInstancesOfClasses:@[[ArticleListController class]]] setBackgroundColor:UIColor.ph_cellBackgroundColor];
    [[UICollectionView appearanceWhenContainedInInstancesOfClasses:@[[ArticleController class]]] setBackgroundColor:UIColor.ph_cellBackgroundColor];
    [[UITableView appearanceWhenContainedInInstancesOfClasses:@[[OCFeedListController class]]] setBackgroundColor:UIColor.ph_popoverBackgroundColor];
    [[UITableView appearanceWhenContainedInInstancesOfClasses:@[[OCSettingsController class]]] setBackgroundColor:UIColor.ph_popoverBackgroundColor];
    
    [UIScrollView appearance].backgroundColor = UIColor.ph_cellBackgroundColor;
    [UIScrollView appearanceWhenContainedInInstancesOfClasses:@[[OCFeedListController class]]].backgroundColor = UIColor.ph_popoverBackgroundColor;

    [[UILabel appearance] setThemeTextColor:UIColor.ph_textColor];

    [[UISwitch appearance] setOnTintColor:UIColor.ph_switchTintColor];
    [[UISwitch appearance] setTintColor:UIColor.ph_switchTintColor];

    [WKWebView appearance].backgroundColor = UIColor.ph_cellBackgroundColor;

    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITextField class]]] setThemeTextColor:UIColor.ph_readTextColor];
    [[UITextField appearance] setTextColor:UIColor.ph_textColor];
    [[UITextView appearance] setTextColor:UIColor.ph_textColor];
    [[UIStepper appearance] setTintColor:UIColor.ph_textColor];

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
            return NSLocalizedString(@"Default", @"Name of the default theme");
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
