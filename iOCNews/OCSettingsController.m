//
//  OCSettingsController.m
//  iOCNews
//
//  Created by Peter Hedlund on 11/15/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "OCSettingsController.h"

@interface OCSettingsController ()

@end

@implementation OCSettingsController

@synthesize syncOnStartSwitch;
@synthesize syncinBackgroundSwitch;
@synthesize showFaviconsSwitch;
@synthesize showThumbnailsSwitch;
@synthesize markWhileScrollingSwitch;
@synthesize syncOnStartCell;
@synthesize syncInBackgroundCell;
@synthesize showFaviconsCell;
@synthesize showThumbnailsCell;
@synthesize markWhileScrollingCell;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.syncOnStartCell.accessoryView = self.syncOnStartSwitch;
    self.syncInBackgroundCell.accessoryView = self.syncinBackgroundSwitch;
    self.showFaviconsCell.accessoryView = self.showFaviconsSwitch;
    self.showThumbnailsCell.accessoryView = self.showThumbnailsSwitch;
    self.markWhileScrollingCell.accessoryView = self.markWhileScrollingSwitch;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    self.syncOnStartSwitch.on = [prefs boolForKey:@"SyncOnStart"];
    self.syncinBackgroundSwitch.on = [prefs boolForKey:@"SyncInBackground"];
    self.showFaviconsSwitch.on = [prefs boolForKey:@"ShowFavicons"];
    self.showThumbnailsSwitch.on = [prefs boolForKey:@"ShowThumbnails"];
    self.markWhileScrollingSwitch.on = [prefs boolForKey:@"MarkWhileScrolling"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    UIViewController *vc = [segue destinationViewController];
    vc.navigationItem.rightBarButtonItem = nil;
}



- (IBAction)syncOnStartChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:self.syncOnStartSwitch.on forKey:@"SyncOnStart"];
}

- (IBAction)syncInBackgroundChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:self.syncinBackgroundSwitch.on forKey:@"SyncInBackground"];
}

- (IBAction)showFaviconsChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:self.showFaviconsSwitch.on forKey:@"ShowFavicons"];
}

- (IBAction)showThumbnailsChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:self.showThumbnailsSwitch.on forKey:@"ShowThumbnails"];
}

- (IBAction)markWhileScrollingChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:self.markWhileScrollingSwitch.on forKey:@"MarkWhileScrolling"];
}

- (IBAction)didTapDone:(id)sender {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
