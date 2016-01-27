//
//  OCLoginController.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2013 Peter Hedlund peter.hedlund@me.com
 
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

#import "OCLoginController.h"
#import "OCAPIClient.h"
#import "PDKeychainBindings.h"
#import "TSMessage.h"

static const NSString *rootPath = @"index.php/apps/news/api/v1-2/";

@interface OCLoginController ()

@property (strong, nonatomic) IBOutlet UILabel *connectLabel;

@end

@implementation OCLoginController

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
    self.serverTextField.delegate = self;
    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;
    self.certificateCell.accessoryView = self.certificateSwitch;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    self.serverTextField.text = [prefs stringForKey:@"Server"];
    self.usernameTextField.text = [[PDKeychainBindings sharedKeychainBindings] objectForKey:(__bridge id)(kSecAttrAccount)];
    self.passwordTextField.text = [[PDKeychainBindings sharedKeychainBindings] objectForKey:(__bridge id)(kSecValueData)];
    self.certificateSwitch.on = [prefs boolForKey:@"AllowInvalidSSLCertificate"];
    if ([OCAPIClient sharedClient].reachabilityManager.isReachable) {
        self.connectLabel.text = NSLocalizedString(@"Reconnect", @"A button title");
    } else {
        self.connectLabel.text = NSLocalizedString(@"Connect", @"A button title");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onCertificateSwitch:(id)sender {
    BOOL textHasChanged = (self.certificateSwitch.on != [[NSUserDefaults standardUserDefaults] boolForKey:@"AllowInvalidSSLCertificate"]);
    if (textHasChanged) {
        self.connectLabel.text = NSLocalizedString(@"Connect", @"A button title");
    } else {
        self.connectLabel.text = NSLocalizedString(@"Reconnect", @"A button title");
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    return 44.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        if (!self.connectLabel.enabled) {
            return;
        }
        [tableView deselectRowAtIndexPath:indexPath animated:true];
        [self.connectionActivityIndicator startAnimating];
        OCAPIClient *client = [[OCAPIClient alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.serverTextField.text, rootPath]]];
        [client setRequestSerializer:[AFJSONRequestSerializer serializer]];
        [client.requestSerializer setAuthorizationHeaderFieldWithUsername:self.usernameTextField.text password:self.passwordTextField.text];

        BOOL allowInvalid = self.certificateSwitch.on;
        client.securityPolicy.allowInvalidCertificates = allowInvalid;
        
        [client GET:@"version" parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSDictionary *jsonDict = nil;
            if (responseObject && [responseObject isKindOfClass:[NSDictionary class]])
            {
                jsonDict = (NSDictionary*)responseObject;
            }
            else
            {
                id json = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
                if (json && [json isKindOfClass:[NSDictionary class]]) {
                    jsonDict = (NSDictionary*)json;
                }
            }
            if (jsonDict) {
                __unused NSString *version = [jsonDict valueForKey:@"version"];
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs setObject:self.serverTextField.text forKey:@"Server"];
                [[PDKeychainBindings sharedKeychainBindings] setObject:self.usernameTextField.text forKey:(__bridge id)(kSecAttrAccount)];
                [[PDKeychainBindings sharedKeychainBindings] setObject:self.passwordTextField.text forKey:(__bridge id)(kSecValueData)];
                [prefs setBool:self.certificateSwitch.on forKey:@"AllowInvalidSSLCertificate"];
                [prefs synchronize];
                [OCAPIClient setSharedClient:nil];
                __unused int status = [[OCAPIClient sharedClient].reachabilityManager networkReachabilityStatus];
                [self.connectionActivityIndicator stopAnimating];
                [TSMessage showNotificationInViewController:self
                                                      title:NSLocalizedString(@"Success", @"A message title")
                                                   subtitle:NSLocalizedString(@"You are now connected to News on your server", @"A message")
                                                      image:nil
                                                       type:TSMessageNotificationTypeSuccess
                                                   duration:TSMessageNotificationDurationAutomatic
                                                   callback:^{
                                                       self.connectLabel.enabled = YES;
                                                       [TSMessage dismissActiveNotification];
                                                   }
                                                buttonTitle:NSLocalizedString(@"Close & Sync", @"A button title")
                                             buttonCallback:^{
                                                 self.connectLabel.enabled = YES;
                                                 [TSMessage dismissActiveNotification];
                                                 [self dismissViewControllerAnimated:YES completion:nil];
                                                 [[NSNotificationCenter defaultCenter] postNotificationName:@"SyncNews" object:self];
                                             }
                                                 atPosition:TSMessageNotificationPositionTop
                                       canBeDismissedByUser:YES];
            } else {
                [self.connectionActivityIndicator stopAnimating];
                [TSMessage showNotificationInViewController:self
                                                      title:NSLocalizedString(@"Connection failure", @"An error message title")
                                                   subtitle:NSLocalizedString(@"Failed to connect to a server. Check your settings.", @"An error message")
                                                      image:nil
                                                       type:TSMessageNotificationTypeError
                                                   duration:TSMessageNotificationDurationEndless
                                                   callback:^{
                                                       self.connectLabel.enabled = YES;
                                                       [TSMessage dismissActiveNotification];
                                                   }
                                                buttonTitle:nil
                                             buttonCallback:^{
                                                 //
                                             }
                                                 atPosition:TSMessageNotificationPositionTop
                                       canBeDismissedByUser:YES];

            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            self.connectLabel.enabled = NO;
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            NSString *message = @"";
            NSString *title = @"";
//            NSLog(@"Status code: %ld", (long)response.statusCode);
            switch (response.statusCode) {
                case 200:
                    title = NSLocalizedString(@"News not found", @"An error message title");
                    message = NSLocalizedString(@"News could not be found on your server. Make sure it is installed and enabled", @"An error message");
                    break;
                case 401:
                    title = NSLocalizedString(@"Unauthorized", @"An error message title");
                    message = NSLocalizedString(@"Check username and password.", @"An error message");
                    break;
                case 404:
                    title = NSLocalizedString(@"Server not found", @"An error message title");
                    message = NSLocalizedString(@"A server installation could not be found. Check the server address.", @"An error message");
                    break;
                default:
                    title = NSLocalizedString(@"Connection failure", @"An error message title");
                    message = NSLocalizedString(@"Failed to connect to a server. Check your settings.", @"An error message");
                    break;
            }
            [self.connectionActivityIndicator stopAnimating];
            [TSMessage showNotificationInViewController:self
                                                  title:title
                                               subtitle:message
                                                  image:nil
                                                   type:TSMessageNotificationTypeError
                                               duration:TSMessageNotificationDurationEndless
                                               callback:^{
                                                   self.connectLabel.enabled = YES;
                                                   [TSMessage dismissActiveNotification];
                                               }
                                            buttonTitle:nil
                                         buttonCallback:^{
                                             //
                                         }
                                             atPosition:TSMessageNotificationPositionTop
                                   canBeDismissedByUser:YES];
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.serverTextField]) {
        [self.usernameTextField becomeFirstResponder];
    }
    if ([textField isEqual:self.usernameTextField]) {
        [self.passwordTextField becomeFirstResponder];
    }
    if ([textField isEqual:self.passwordTextField]) {
        [textField resignFirstResponder];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *labelText = @"Reconnect";
    BOOL textHasChanged = NO;
    
    NSMutableString *proposedNewString = [NSMutableString stringWithString:textField.text];
    [proposedNewString replaceCharactersInRange:range withString:string];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([textField isEqual:self.serverTextField]) {
        textHasChanged = (![proposedNewString isEqualToString:[prefs stringForKey:@"Server"]]);
    }
    if ([textField isEqual:self.usernameTextField]) {
        textHasChanged = (![proposedNewString isEqualToString:[[PDKeychainBindings sharedKeychainBindings] objectForKey:(__bridge id)(kSecAttrAccount)]]);
    }
    if ([textField isEqual:self.passwordTextField]) {
        textHasChanged = (![proposedNewString isEqualToString:[[PDKeychainBindings sharedKeychainBindings] objectForKey:(__bridge id)(kSecValueData)]]);
    }
    if (!textHasChanged) {
        textHasChanged = (self.certificateSwitch.on != [prefs boolForKey:@"AllowInvalidSSLCertificate"]);
    }
    if (textHasChanged) {
        labelText = @"Connect";
    }
    self.connectLabel.text = labelText;
    return YES;
}

@end
