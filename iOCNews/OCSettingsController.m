//
//  OCSettingsController.m
//  iOCNews

/************************************************************************
 
 Copyright 2013-2015 Peter Hedlund peter.hedlund@me.com
 
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

#import "OCSettingsController.h"
#import "OCAPIClient.h"
#import "PHThemeManager.h"

@implementation OCSettingsController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    self.syncOnStartSwitch.on = [prefs boolForKey:@"SyncOnStart"];
    self.syncinBackgroundSwitch.on = [prefs boolForKey:@"SyncInBackground"];
    self.showFaviconsSwitch.on = [prefs boolForKey:@"ShowFavicons"];
    self.showThumbnailsSwitch.on = [prefs boolForKey:@"ShowThumbnails"];
    self.markWhileScrollingSwitch.on = [prefs boolForKey:@"MarkWhileScrolling"];
    if ([OCAPIClient sharedClient].reachabilityManager.isReachable) {
        self.statusLabel.text = NSLocalizedString(@"Logged In", @"A status label indicating that the user is logged in");
    } else {
        self.statusLabel.text =  NSLocalizedString(@"Not Logged In", @"A status label indicating that the user is not logged in");
    }
    self.themeLabel.text = PHThemeManager.sharedManager.themeName;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
            mailViewController.mailComposeDelegate = self;
            [mailViewController setToRecipients:[NSArray arrayWithObject:@"support@peterandlinda.com"]];
            [mailViewController setSubject:@"CloudNews Support Request"];
            [mailViewController setMessageBody:@"<Please state your question or problem here>" isHTML:NO ];
            mailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:mailViewController animated:YES completion:nil];
        }
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    UIViewController *vc = [segue destinationViewController];
    vc.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - Switches

- (IBAction)syncOnStartChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[(UISwitch*)sender isOn] forKey:@"SyncOnStart"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)syncInBackgroundChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[(UISwitch*)sender isOn] forKey:@"SyncInBackground"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)showFaviconsChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[(UISwitch*)sender isOn] forKey:@"ShowFavicons"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)showThumbnailsChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[(UISwitch*)sender isOn] forKey:@"ShowThumbnails"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)markWhileScrollingChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[(UISwitch*)sender isOn] forKey:@"MarkWhileScrolling"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Button

- (IBAction)onDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
