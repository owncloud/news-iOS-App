//
//  OCFeedSettingsController.m
//  FeedDeck
//
//  Created by Peter Hedlund on 11/1/12.
//
//

#import "OCFeedSettingsController.h"
#import "OCNewsHelper.h"

@interface OCFeedSettingsController () {
    NSArray *_cells;
}

@end

@implementation OCFeedSettingsController

@synthesize delegate;
@synthesize titleTextField;
@synthesize fullArticleSwitch;
@synthesize readerSwitch;
@synthesize feed = _feed;

- (void)viewDidLoad {
    [super viewDidLoad];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.navigationItem.leftBarButtonItem = nil;
        if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Extra

- (void)setFeed:(Feed *)feed
{
    if (_feed != feed) {
        _feed = feed;
        
        self.titleTextField.text = feed.extra.displayTitle;
        self.fullArticleSwitch.on = feed.extra.preferWebValue;
        self.readerSwitch.on = feed.extra.useReaderValue;
        self.readerSwitch.enabled = self.fullArticleSwitch.on;
    }
}

- (IBAction)doSave:(id)sender {
    self.feed.extra.displayTitle = self.titleTextField.text;
    self.feed.extra.preferWebValue = self.fullArticleSwitch.on;
    self.feed.extra.useReaderValue = self.readerSwitch.on;
    [[OCNewsHelper sharedHelper] saveContext];
    if (self.delegate) {
        [self.delegate feedSettingsUpdate:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)fullArticleStateChanged:(id)sender {
    self.readerSwitch.enabled = self.fullArticleSwitch.on;
}

- (IBAction)doCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
