//
//  WebController.h
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

#import <UIKit/UIKit.h>
#import "PHPrefViewController.h"
#import "Item.h"
#import "JCGridMenuController.h"

@interface OCWebController : UIViewController <UIWebViewDelegate, UIGestureRecognizerDelegate, PHPrefViewControllerDelegate, JCGridMenuControllerDelegate>

@property (nonatomic, strong) Item *item;
@property (nonatomic, strong) UIWebView* webView;
@property (nonatomic, strong, readonly) JCGridMenuController *menuController;
@property (nonatomic, strong, readonly) JCGridMenuRow *keepUnread;
@property (nonatomic, strong, readonly) JCGridMenuRow *star;
@property (nonatomic, strong, readonly) JCGridMenuRow *backgroundMenuRow;
@property (nonatomic, strong, readonly) UIBarButtonItem *menuBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *stopBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *actionBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *textBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *starBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *unstarBarButtonItem;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *nextArticleRecognizer;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *previousArticleRecognizer;

- (IBAction) doGoBack:(id)sender;
- (IBAction) doGoForward:(id)sender;
- (IBAction) doReload:(id)sender;
- (IBAction) doStop:(id)sender;
- (IBAction) doInfo:(id)sender;
- (IBAction) doText:(id)sender event:(UIEvent*)event;
- (IBAction) doStar:(id)sender;

@end
