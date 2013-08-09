//
//  OCFeedSettingsController.h
//  FeedDeck
//
//  Created by Peter Hedlund on 11/1/12.
//
//

#import <UIKit/UIKit.h>
#import "Feed.h"

@protocol OCFeedSettingsDelegate;

@interface OCFeedSettingsController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, unsafe_unretained) id <OCFeedSettingsDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet UISwitch *fullArticleSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *readerSwitch;

@property (nonatomic, strong) Feed *feed;

- (IBAction) doSave:(id)sender;
- (IBAction) doCancel:(id)sender;
- (IBAction) fullArticleStateChanged:(id)sender;

@end

// delegate methods
@protocol OCFeedSettingsDelegate <NSObject>
@optional
- (void) feedSettingsUpdate:(OCFeedSettingsController *)settings;
@end
