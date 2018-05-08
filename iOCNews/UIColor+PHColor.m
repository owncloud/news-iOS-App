//
//  UIColor+PHColor.m
//  PMC Reader
//
//  Created by Peter Hedlund on 9/29/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "UIColor+PHColor.h"

#define kPHBackgroundColorArray        @[kPHWhiteBackgroundColor, kPHSepiaBackgroundColor, kPHNightBackgroundColor]
#define kPHCellBackgroundColorArray    @[kPHWhiteCellBackgroundColor, kPHSepiaCellBackgroundColor, kPHNightCellBackgroundColor]
#define kPHCellSelectionColorArray     @[kPHWhiteCellSelectionColor, kPHSepiaCellSelectionColor, kPHNightCellSelectionColor]
#define kPHIconColorArray              @[kPHWhiteIconColor, kPHSepiaIconColor, kPHNightIconColor]
#define kPHTextColorArray              @[kPHWhiteTextColor, kPHSepiaTextColor, kPHNightTextColor]
#define kPHReadTextColorArray          @[[UIColor colorWithWhite:0.0 alpha:0.40], [UIColor colorWithWhite:0.41 alpha:1.0], [UIColor colorWithWhite:0.41 alpha:1.0]]
#define kPHLinkColorArray              @[kPHWhiteLinkColor, kPHSepiaLinkColor, kPHNightLinkColor]
#define kPHPopoverBackgroundColorArray @[kPHWhitePopoverBackgroundColor, kPHSepiaPopoverBackgroundColor, kPHNightPopoverBackgroundColor]
#define kPHPopoverButtonColorArray     @[kPHWhitePopoverButtonColor, kPHSepiaPopoverButtonColor, kPHNightPopoverButtonColor]
#define kPHPopoverBorderColorArray     @[kPHWhitePopoverBorderColor, kPHSepiaPopoverBorderColor, kPHNightPopoverBorderColor]

@implementation UIColor (PHColor)

+ (UIColor *)backgroundColor {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    return [kPHBackgroundColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)cellBackgroundColor {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    return [kPHCellBackgroundColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)cellSelectionColor {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    return [kPHCellSelectionColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)iconColor {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    return [kPHIconColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)textColor {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    return [kPHTextColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)readTextColor {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    return [kPHReadTextColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)linkColor {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    return [kPHLinkColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)popoverBackgroundColor {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    return [kPHPopoverBackgroundColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)popoverButtonColor {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    return [kPHPopoverButtonColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)popoverBorderColor {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    return [kPHPopoverBorderColorArray objectAtIndex:backgroundIndex];
}

+ (UIColor *)popoverIconColor {
    NSInteger backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    if (backgroundIndex == 2) {
        return kPHNightTextColor;
    }
    return [kPHIconColorArray objectAtIndex:backgroundIndex];
}

@end
