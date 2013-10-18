//
//  OCFolderTableViewController.m
//  iOCNews
//
//  Created by Peter Hedlund on 10/17/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "OCFolderTableViewController.h"
#import "Folder.h"

@interface OCFolderTableViewController () {
    NSNumber *_selectedFolderId;
}

@end

@implementation OCFolderTableViewController

@synthesize delegate = _delegate;
@synthesize feed;
@synthesize folders;

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
}

- (void)viewDidAppear:(BOOL)animated {
    _selectedFolderId = self.feed.folderId;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.folders.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FolderCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    if (indexPath.row == 0) {
        cell.textLabel.text = @"(No Folder)";
        if ([_selectedFolderId isEqualToNumber:[NSNumber numberWithInt:0]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else {
        Folder *folder = [self.folders objectAtIndex:indexPath.row - 1];
        cell.textLabel.text = folder.name;
        NSArray *folderIds = [self.folders valueForKeyPath:@"myId"];
        int folderIdIndex = [folderIds indexOfObject:_selectedFolderId];
        if (folderIdIndex == indexPath.row - 1) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (_delegate != nil) {
        if (indexPath.row == 0) {
            _selectedFolderId = [NSNumber numberWithInt:0];
            [_delegate folderSelected:[NSNumber numberWithInt:0]];
        } else {
            NSNumber *newFolderId = [[self.folders valueForKeyPath:@"myId"] objectAtIndex:(indexPath.row - 1)];
            _selectedFolderId = newFolderId;
            [_delegate folderSelected:newFolderId];
        }
	}
    [self.tableView reloadData];
}

@end
