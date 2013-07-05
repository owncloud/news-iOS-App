//
//  OCLoginController.h
//  iOCNews
//
//  Created by Peter Hedlund on 7/2/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeychainItemWrapper.h"

@interface OCLoginController : UITableViewController

@property (nonatomic, strong, readonly) KeychainItemWrapper *keychain;

@property (strong, nonatomic) IBOutlet UITextField *serverTextField;
@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;

@property (strong, nonatomic) IBOutlet UILabel *versionLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *connectionActivityIndicator;

- (IBAction)doDone:(id)sender;

@end
