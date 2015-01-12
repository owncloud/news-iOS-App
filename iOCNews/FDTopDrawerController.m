//
//  FDDrawerController.m
//  FeedDeck
//
//  Created by Peter Hedlund on 5/31/14.
//
//

#import "FDTopDrawerController.h"
#import "MMDrawerVisualState.h"
#import "OCWebController.h"

@interface FDTopDrawerController ()

@end

@implementation FDTopDrawerController

@synthesize webController;

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
    self.animationVelocity = self.animationVelocity * 4;
    //[self setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
    self.openDrawerGestureModeMask =     MMOpenDrawerGestureModePanningNavigationBar | MMOpenDrawerGestureModeBezelPanningCenterView |    MMOpenDrawerGestureModeCustom;

    [self setCloseDrawerGestureModeMask:MMCloseDrawerGestureModePanningCenterView | MMCloseDrawerGestureModePanningNavigationBar | MMCloseDrawerGestureModeTapCenterView | MMCloseDrawerGestureModeTapNavigationBar];
    self.showsShadow = NO;
    [self setDrawerVisualStateBlock:^(MMDrawerController *drawerController, MMDrawerSide drawerSide, CGFloat percentVisible) {
        MMDrawerControllerDrawerVisualStateBlock block = [MMDrawerVisualState parallaxVisualStateBlockWithParallaxFactor:2.0];
        if (block){
            block(drawerController, drawerSide, percentVisible);
        }
    }];
    self.maximumLeftDrawerWidth = [UIScreen mainScreen].bounds.size.width;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    self.maximumLeftDrawerWidth = size.width;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    BOOL result = [super gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];

    if (self.openSide == MMDrawerSideNone) {
        CGPoint loc = [touch locationInView:webController.webView];
        float h = self.webController.webView.frame.size.height;
        float q = h / 4;
        if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
            if (loc.y < q) {
                result = YES;
            }
            if (loc.y > (3 * q)) {
                result = YES;
            }
            //result = NO;
        }
        //result = NO;
        
    }
    return result;
}

- (void)openDrawerSide:(MMDrawerSide)drawerSide animated:(BOOL)animated velocity:(CGFloat)velocity animationOptions:(UIViewAnimationOptions)options completion:(void (^)(BOOL))completion
{
    [super openDrawerSide:drawerSide animated:animated velocity:velocity animationOptions:options completion:completion];
    if (self.webController.webView) {
        [self.webController.webView removeGestureRecognizer:self.webController.nextArticleRecognizer];
        [self.webController.webView removeGestureRecognizer:self.webController.previousArticleRecognizer];
        self.webController.webView.scrollView.scrollsToTop = NO;
    }
}

- (void)closeDrawerAnimated:(BOOL)animated velocity:(CGFloat)velocity animationOptions:(UIViewAnimationOptions)options completion:(void (^)(BOOL))completion
{
    [super closeDrawerAnimated:animated velocity:velocity animationOptions:options completion:completion];
    if (self.webController.webView) {
        [self.webController.webView addGestureRecognizer:self.webController.nextArticleRecognizer];
        [self.webController.webView addGestureRecognizer:self.webController.previousArticleRecognizer];
    }
}

- (CGSize)screenSize {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return CGSizeMake(screenSize.height, screenSize.width);
    }
    return screenSize;
}

@end
