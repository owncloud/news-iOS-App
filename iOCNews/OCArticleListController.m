//
//  SelectionController.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2012-2013 Peter Hedlund peter.hedlund@me.com
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 *************************************************************************/

#import "OCArticleListController.h"
#import "OCArticleCell.h"
#import "OCWebController.h"
#import "IIViewDeckController.h"
#import "NSString+HTML.h"
#import "UILabel+VerticalAlignment.h"
#import "AFNetworking.h"
#import "OCAPIClient.h"
#import "OCArticleImage.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface OCArticleListController () {
    int currentIndex;
}

- (void) configureView;
- (void) scrollToTop;
- (void) previousArticle:(NSNotification*)n;
- (void) nextArticle:(NSNotification*)n;
- (void) articleChangeInFeed:(NSNotification*)n;

@end

@implementation OCArticleListController

@synthesize markBarButtonItem;
@synthesize feedRefreshControl;
@synthesize feed, articles;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;

        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.
    
    NSDictionary *detail = (NSDictionary *) self.detailItem;
    self.navigationItem.title = [detail objectForKey:@"title"];
    self.articles = [NSMutableArray new];
    [self.tableView reloadData];
/*
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    docDir = [docDir URLByAppendingPathComponent:[detail objectForKey:@"GUID"] isDirectory:NO];
    docDir = [docDir URLByAppendingPathExtension:@"plist"];
    NSString *archivePath = [docDir path];

    if ([fm fileExistsAtPath:archivePath]) {
        self.feed = [NSKeyedUnarchiver unarchiveObjectWithFile:archivePath];
    } else { */
        //Shouldn't really happen, but just to be safe
        self.feed = [NSMutableDictionary dictionaryWithDictionary:self.detailItem];
        //self.feed.title = [detail objectForKey:@"Title"];
        //self.feed.url = [NSURL URLWithString:[detail objectForKey:@"XMLUrl"]];
        //self.feed.guid = [detail objectForKey:@"GUID"];
/*    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        [self.feedRefreshControl performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:YES];
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(scrollToTop) withObject:nil waitUntilDone:NO];
    });
*/
    if (([[OCAPIClient sharedClient] networkReachabilityStatus] > 0)) {
        OCAPIClient *client = [OCAPIClient sharedClient];
        NSString *feedId = [self.feed objectForKey:@"id"];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:150], @"batchSize",
                                [NSNumber numberWithInt:0], @"offset",
                                [NSNumber numberWithInt:0], @"type",
                                feedId, @"id",
                                @"true", @"getRead", nil];
        
        NSMutableURLRequest *request = [client requestWithMethod:@"GET" path:@"items" parameters:params];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            NSLog(@"Feeds: %@", JSON);
            NSDictionary *jsonDict = (NSDictionary *) JSON;
            
            self.articles = [NSMutableArray arrayWithArray:[jsonDict objectForKey:@"items"]];
            [self.refreshControl endRefreshing];
            [self.tableView reloadData];
            [self scrollToTop];
            
        } failure:nil];
        [client enqueueHTTPRequestOperation:operation];
    }
}

- (void) scrollToTop {
    int unreadCount = [(NSNumber*)[self.feed valueForKey:@"unreadCount"] intValue];
    self.markBarButtonItem.enabled = (unreadCount > 0);
    if (self.articles.count > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 5.0f;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *items = [NSArray arrayWithObjects:
                      fixedSpace,
                      self.markBarButtonItem,
                      flexibleSpace,
                      nil];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
    toolbar.items = items;
    toolbar.tintColor = self.navigationController.navigationBar.tintColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
    self.markBarButtonItem.enabled = NO;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"OCArticleCell" bundle:nil] forCellReuseIdentifier:@"ArticleCell"];
    self.tableView.rowHeight = 132;

    //self.refreshControl = self.feedRefreshControl;
    UINavigationController *navController = (UINavigationController*)self.viewDeckController.centerController;
    self.detailViewController = (OCWebController*)navController.topViewController;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previousArticle:) name:@"LeftTapZone" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextArticle:) name:@"RightTapZone" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleChangeInFeed:) name:@"ArticleChangeInFeed" object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.articles.count > 0) {
        return self.articles.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OCArticleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArticleCell"];

    NSDictionary *article = [self.articles objectAtIndex:indexPath.row];

    cell.titleLabel.text = [[article objectForKey:@"title"] stringByConvertingHTMLToPlainText];
    [cell.titleLabel setTextVerticalAlignment:UITextVerticalAlignmentTop];
    NSString *dateLabelText = @"";
    NSString *author = [article objectForKey:@"author"];
    if (![author isKindOfClass:[NSNull class]]) {
        
        if (author.length > 0) {
            const int clipLength = 50;
            if([author length] > clipLength) {
                dateLabelText = [NSString stringWithFormat:@"%@...",[author substringToIndex:clipLength]];
            } else {
                dateLabelText = author;
            }
        }
    }
    NSNumber *dateNumber = [article valueForKey:@"pubDate"];
    if (![dateNumber isKindOfClass:[NSNull class]]) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dateNumber doubleValue]];
        if (date) {
            if (dateLabelText.length > 0) {
                dateLabelText = [dateLabelText stringByAppendingString:@" on "];
            }
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            dateFormat.dateStyle = NSDateFormatterMediumStyle;
            dateFormat.timeStyle = NSDateFormatterShortStyle;
            dateLabelText = [dateLabelText stringByAppendingString:[dateFormat stringFromDate:date]];
        }
    }
    cell.dateLabel.text = dateLabelText;
    
    NSString *summary = [article objectForKey:@"body"];
    if ([summary rangeOfString:@"<style>" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        if ([summary rangeOfString:@"</style>" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            NSRange r;
            r.location = [summary rangeOfString:@"<style>" options:NSCaseInsensitiveSearch].location;
            r.length = [summary rangeOfString:@"</style>" options:NSCaseInsensitiveSearch].location - r.location + 8;
            NSString *sub = [summary substringWithRange:r];
            summary = [summary stringByReplacingOccurrencesOfString:sub withString:@""];
        }
    }
    cell.summaryLabel.text = [summary stringByConvertingHTMLToPlainText];
    [cell.summaryLabel setTextVerticalAlignment:UITextVerticalAlignmentTop];
    NSNumber *read = [article valueForKey:@"unread"];
    if ([read intValue] == 1) {
        cell.summaryLabel.textColor = [UIColor darkTextColor];
        cell.titleLabel.textColor = [UIColor darkTextColor];
        cell.dateLabel.textColor = [UIColor darkTextColor];
        cell.articleImage.alpha = 1.0f;
    } else {
        cell.summaryLabel.textColor = UIColorFromRGB(0x696969);
        cell.titleLabel.textColor = UIColorFromRGB(0x696969);
        cell.dateLabel.textColor = UIColorFromRGB(0x696969);
        cell.articleImage.alpha = 0.4f;
    }
   
    [cell.articleImage setImageWithURL:[NSURL URLWithString:[OCArticleImage findImage:summary]] placeholderImage:[UIImage imageNamed:@"placeholder"]];

    return cell;

}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    currentIndex = indexPath.row;
    NSDictionary *object = (NSDictionary*)[self.articles objectAtIndex:indexPath.row];
    self.detailViewController.feedTitle = [self.feed valueForKey:@"title"];
    self.detailViewController.detailItem = object;
    [self.viewDeckController closeLeftView];
    NSNumber *read = [object valueForKey:@"unread"];
    if ([read intValue] == 1) {
        if (([[OCAPIClient sharedClient] networkReachabilityStatus] > 0)) {
            
            NSString *myId = [object valueForKey:@"id"];
            
            OCAPIClient *client = [OCAPIClient sharedClient];
            
            NSMutableURLRequest *request = [client requestWithMethod:@"PUT" path:[NSString stringWithFormat:@"items/%@/read", myId] parameters:nil];
            
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSMutableDictionary *updatedArticle = [NSMutableDictionary dictionaryWithDictionary:object];
                [updatedArticle setValue:[NSNumber numberWithInt:0] forKey:@"unread"];
                [self.articles replaceObjectAtIndex:[indexPath row] withObject:updatedArticle];
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                
                int unreadCount = [(NSNumber*)[self.feed valueForKey:@"unreadCount"] intValue];
                --unreadCount;
                [self.feed setValue:[NSNumber numberWithInt:unreadCount] forKey:@"unreadCount"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DecreaseNewCount" object:self userInfo:[NSDictionary dictionaryWithObject:self.feed forKey:@"Feed"]];
                NSLog(@"Success");
            } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failure");
            }];
            [client enqueueHTTPRequestOperation:operation];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //NSLog(@"We have scrolled");
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self markRowsRead];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self markRowsRead];
}


#pragma mark - Actions

- (IBAction)doRefresh:(id)sender {
//
}

- (IBAction)doMarkRead:(id)sender {
    if (([[OCAPIClient sharedClient] networkReachabilityStatus] > 0)) {
        
        __block int unreadCount = [(NSNumber*)[self.feed valueForKey:@"unreadCount"] intValue];
        
        if (unreadCount > 0) {
            if (self.articles.count > 0) {
                
                NSMutableIndexSet *indicesForObjectsToReplace = [NSMutableIndexSet new];
                NSMutableArray *objectsToReplace = [NSMutableArray new];
                NSMutableArray *idsToMarkRead = [NSMutableArray new];
                
                [self.articles enumerateObjectsUsingBlock:^(NSDictionary *article, NSUInteger idx, BOOL *stop) {
                    NSNumber *unread = [article valueForKey:@"unread"];
                    if ([unread intValue] == 1) {
                        [indicesForObjectsToReplace addIndex:idx];
                        
                        NSMutableDictionary *updatedArticle = [NSMutableDictionary dictionaryWithDictionary:article];
                        [updatedArticle setValue:[NSNumber numberWithInt:0] forKey:@"unread"];
                        [objectsToReplace addObject:updatedArticle];
                        [idsToMarkRead addObject:[article valueForKey:@"id"]];
                    }
                }];
                [[OCAPIClient sharedClient] putPath:@"items/read/multiple" parameters:[NSDictionary dictionaryWithObject:idsToMarkRead forKey:@"items"] success:nil failure:nil];
                
                
                [self.articles replaceObjectsAtIndexes:indicesForObjectsToReplace
                                           withObjects:objectsToReplace];
                
                [self.feed setValue:[NSNumber numberWithInt:0] forKey:@"unreadCount"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ClearNewCount" object:self userInfo:[NSDictionary dictionaryWithObject:self.feed forKey:@"Feed"]];
                [self.tableView reloadData];
                self.markBarButtonItem.enabled = NO;
            }
        }
    }
}


#pragma  mark - Feedparser delegate

- (void) markRowsRead {
    if (([[OCAPIClient sharedClient] networkReachabilityStatus] > 0)) {

        __block int unreadCount = [(NSNumber*)[self.feed valueForKey:@"unreadCount"] intValue];
        
        if (unreadCount > 0) {
            NSArray * vCells = self.tableView.indexPathsForVisibleRows;
            __block int row = 0;
            NSMutableArray *updatedIndexes;
            if (vCells.count > 0) {
                NSIndexPath *topCell = [vCells objectAtIndex:0];
                row = topCell.row;
                NSLog(@"Top row: %d", row);
            }
            
            if (self.articles.count > 0) {
                updatedIndexes = [[NSMutableArray alloc] init];
                
                NSMutableIndexSet *indicesForObjectsToReplace = [NSMutableIndexSet new];
                NSMutableArray *objectsToReplace = [NSMutableArray new];
                NSMutableArray *idsToMarkRead = [NSMutableArray new];
                
                [self.articles enumerateObjectsUsingBlock:^(NSDictionary *article, NSUInteger idx, BOOL *stop) {
                    if (idx >= row) {
                        *stop = YES;
                    }
                    NSNumber *unread = [article valueForKey:@"unread"];
                    if ([unread intValue] == 1) {
                        --unreadCount;
                        [indicesForObjectsToReplace addIndex:idx];
                        
                        NSMutableDictionary *updatedArticle = [NSMutableDictionary dictionaryWithDictionary:article];
                        [updatedArticle setValue:[NSNumber numberWithInt:0] forKey:@"unread"];
                        [objectsToReplace addObject:updatedArticle];
                        
                        NSIndexPath * path = [NSIndexPath indexPathForRow:idx inSection:0];
                        [updatedIndexes addObject:path];
                        
                        [idsToMarkRead addObject:[article valueForKey:@"id"]];
                    }
                }];
                [[OCAPIClient sharedClient] putPath:@"items/read/multiple" parameters:[NSDictionary dictionaryWithObject:idsToMarkRead forKey:@"items"] success:nil failure:nil];
                
                
                [self.articles replaceObjectsAtIndexes:indicesForObjectsToReplace
                                           withObjects:objectsToReplace];
                
                [self.feed setValue:[NSNumber numberWithInt:unreadCount] forKey:@"unreadCount"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DecreaseNewCount" object:self userInfo:[NSDictionary dictionaryWithObject:self.feed forKey:@"Feed"]];
                [self.tableView reloadRowsAtIndexPaths:updatedIndexes withRowAnimation:UITableViewRowAnimationNone];
                self.markBarButtonItem.enabled = (unreadCount > 0);
            }
        }
    }
}

#pragma mark - Toolbar buttons

- (UIBarButtonItem *)markBarButtonItem {
    if (!markBarButtonItem) {
        markBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mark"] style:UIBarButtonItemStylePlain target:self action:@selector(doMarkRead:)];
        markBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return markBarButtonItem;
}

#pragma mark - Tap navigation

- (void) previousArticle:(NSNotification *)n {
    if (currentIndex != 0) {
        --currentIndex;
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0]];
    }
}

- (void) nextArticle:(NSNotification *)n {
    if (currentIndex < ([self.tableView numberOfRowsInSection:0] - 1)) {
        ++currentIndex;
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0]];
    }
}

- (void) articleChangeInFeed:(NSNotification *)n {
/*    NSString * articleText = [n.userInfo objectForKey:@"ArticleText"];
    FDArticle *a = (FDArticle*)[self.articles objectAtIndex:currentIndex];
    a.readable = articleText;

    BOOL success = [self.feed writeToFile];
    if (success) {
        [self configureView];
    } */
}

- (UIRefreshControl *)feedRefreshControl {
    if (!feedRefreshControl) {
        feedRefreshControl = [[UIRefreshControl alloc] init];
        [feedRefreshControl addTarget:self action:@selector(doRefresh:) forControlEvents:UIControlEventValueChanged];
    }
    
    return feedRefreshControl;
}

@end
