//
//  OCThemeSettingsController.m
//  iOCNews
//
//  Created by Peter Hedlund on 4/15/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

#import "OCThemeSettingsController.h"
#import "PHThemeManager.h"

@interface OCThemeSettingsController ()

@property (strong, nonatomic) IBOutlet UITableViewCell *defaultCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sepiaCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *nightCell;

@end

@implementation OCThemeSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self update];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            PHThemeManager.sharedManager.currentTheme = PHThemeDefault;
            break;
        case 1:
            PHThemeManager.sharedManager.currentTheme = PHThemeSepia;
            break;
        case 2:
            PHThemeManager.sharedManager.currentTheme = PHThemeNight;
            break;

        default:
            break;
    }
    [self update];
}

- (void)update {
    self.defaultCell.accessoryType = UITableViewCellAccessoryNone;
    self.sepiaCell.accessoryType = UITableViewCellAccessoryNone;
    self.nightCell.accessoryType = UITableViewCellAccessoryNone;
    switch (PHThemeManager.sharedManager.currentTheme) {
        case PHThemeDefault:
            self.defaultCell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        case PHThemeSepia:
            self.sepiaCell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        case PHThemeNight:
            self.nightCell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        default:
            break;
    }
}

@end
