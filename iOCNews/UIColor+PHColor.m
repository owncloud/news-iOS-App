//
//  UIColor+PHColor.m
//
//  Created by Peter Hedlund on 9/29/13.
//  Copyright (c) 2013-2019 Peter Hedlund. All rights reserved.
//

#import "UIColor+PHColor.h"

@implementation UIColor (PHColor)

+ (UIColor *)ph_backgroundColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhiteBackground"], [UIColor colorNamed:@"PHSepiaBackground"], [UIColor colorNamed:@"PHDarkBackground"]];
    return [colors objectAtIndex:backgroundIndex];
}

+ (UIColor *)ph_cellBackgroundColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhiteCellBackground"], [UIColor colorNamed:@"PHSepiaCellBackground"], [UIColor colorNamed:@"PHDarkCellBackground"]];
    return [colors objectAtIndex:backgroundIndex];

}

+ (UIColor *)ph_cellSelectionColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhiteCellSelection"], [UIColor colorNamed:@"PHSepiaCellSelection"], [UIColor colorNamed:@"PHDarkCellSelection"]];
    return [colors objectAtIndex:backgroundIndex];
}

+ (UIColor *)ph_iconColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhiteIcon"], [UIColor colorNamed:@"PHSepiaIcon"], [UIColor colorNamed:@"PHDarkIcon"]];
    return [colors objectAtIndex:backgroundIndex];
}

+ (UIColor *)ph_textColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhiteText"], [UIColor colorNamed:@"PHSepiaText"], [UIColor colorNamed:@"PHDarkText"]];
    return [colors objectAtIndex:backgroundIndex];
}

+ (UIColor *)ph_readTextColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhiteReadText"], [UIColor colorNamed:@"PHSepiaReadText"], [UIColor colorNamed:@"PHDarkReadText"]];
    return [colors objectAtIndex:backgroundIndex];
}

+ (UIColor *)ph_linkColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhiteLink"], [UIColor colorNamed:@"PHSepiaLink"], [UIColor colorNamed:@"PHDarkLink"]];
    return [colors objectAtIndex:backgroundIndex];
}

+ (UIColor *)ph_popoverBackgroundColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhitePopoverBackground"], [UIColor colorNamed:@"PHSepiaPopoverBackground"], [UIColor colorNamed:@"PHDarkPopoverBackground"]];
    return [colors objectAtIndex:backgroundIndex];
}

+ (UIColor *)ph_popoverButtonColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhitePopoverButton"], [UIColor colorNamed:@"PHSepiaPopoverButton"], [UIColor colorNamed:@"PHDarkPopoverButton"]];
    return [colors objectAtIndex:backgroundIndex];
}

+ (UIColor *)ph_popoverBorderColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhitePopoverBorder"], [UIColor colorNamed:@"PHSepiaPopoverBorder"], [UIColor colorNamed:@"PHDarkPopoverBorder"]];
    return [colors objectAtIndex:backgroundIndex];
}

+ (UIColor *)ph_popoverIconColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhiteIcon"], [UIColor colorNamed:@"PHSepiaIcon"], [UIColor colorNamed:@"PHDarkIcon"]];
    return [colors objectAtIndex:backgroundIndex];
}

+ (UIColor *)ph_switchTintColor {
    NSInteger backgroundIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentTheme"];
    NSArray *colors = @[[UIColor colorNamed:@"PHWhitePopoverBorder"], [UIColor colorNamed:@"PHSepiaPopoverBorder"], [UIColor colorNamed:@"PHDarkPopoverButton"]];
    return [colors objectAtIndex:backgroundIndex];
}

@end
