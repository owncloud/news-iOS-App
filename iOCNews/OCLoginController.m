//
//  OCLoginController.m
//  iOCNews
//
//  Created by Peter Hedlund on 7/2/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "OCLoginController.h"
#import "OCAPIClient.h"
#import "KeychainItemWrapper.h"

static const NSString *rootPath = @"index.php/apps/news/api/v1-2/";

@interface OCLoginController ()

@end

@implementation OCLoginController

@synthesize keychain;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSString *version = @"Version ";
    version = [version stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
	self.versionLabel.text = version;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    self.serverTextField.text = [prefs stringForKey:@"Server"];
    self.usernameTextField.text = [self.keychain objectForKey:(__bridge id)(kSecAttrAccount)];
    self.passwordTextField.text = [self.keychain objectForKey:(__bridge id)(kSecValueData)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:true];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if (![self.serverTextField.text isEqualToString:[prefs stringForKey:@"Server"]] ||
            ![self.usernameTextField.text isEqualToString:[self.keychain objectForKey:(__bridge id)(kSecAttrAccount)]] ||
            ![self.passwordTextField.text isEqualToString:[self.keychain objectForKey:(__bridge id)(kSecValueData)]]) {
            
            AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.serverTextField.text, rootPath]]];
            [client setAuthorizationHeaderWithUsername:self.usernameTextField.text password:self.passwordTextField.text];
            
            [client getPath:@"version" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Connection successful");
                [prefs setObject:self.serverTextField.text forKey:@"Server"];
                [self.keychain setObject:self.usernameTextField.text forKey:(__bridge id)(kSecAttrAccount)];
                [self.keychain setObject:self.passwordTextField.text forKey:(__bridge id)(kSecValueData)];
                [OCAPIClient setSharedClient:nil];
                [tableView reloadData];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failure to connect");
            }];

        }
    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *result = @"";

    if (section == 1) {
        if ([[OCAPIClient sharedClient] networkReachabilityStatus] > 0) {
            result = [NSString stringWithFormat:@"Connected to \"%@\".", [[NSUserDefaults standardUserDefaults] stringForKey:@"Server"]];
        } else {
            result = @"Currently not connected to an OwnCloud News server";
        }
    }
    return result;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    CGFloat result = 0.0f;
    if (section == 1) {
        result = 50.0f;
    }
    return result;
}

- (KeychainItemWrapper *)keychain {
    if (!keychain) {
        keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"iOCNews" accessGroup:nil];
        [keychain setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
    }
    return keychain;
}

@end
