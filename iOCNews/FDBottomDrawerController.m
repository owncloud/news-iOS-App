//
//  FDDrawerController.m
//  FeedDeck
//
//  Created by Peter Hedlund on 5/31/14.
//
//

#import "FDBottomDrawerController.h"
#import "MMDrawerVisualState.h"

@interface FDBottomDrawerController ()

@end

@implementation FDBottomDrawerController

@synthesize feedListController;
@synthesize articleListController;

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
    [self setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
    [self setCloseDrawerGestureModeMask:MMCloseDrawerGestureModePanningCenterView | MMCloseDrawerGestureModePanningNavigationBar | MMCloseDrawerGestureModeTapCenterView | MMCloseDrawerGestureModeTapNavigationBar];
    self.showsShadow = NO;
    [self setDrawerVisualStateBlock:^(MMDrawerController *drawerController, MMDrawerSide drawerSide, CGFloat percentVisible) {
        MMDrawerControllerDrawerVisualStateBlock block = [MMDrawerVisualState parallaxVisualStateBlockWithParallaxFactor:2.0];
        if (block){
            block(drawerController, drawerSide, percentVisible);
        }
    }];
    [self willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        self.maximumLeftDrawerWidth = 320.0f;
    } else {
        float width;
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
            width = CGRectGetHeight([UIScreen mainScreen].bounds);
        } else {
            width = CGRectGetWidth([UIScreen mainScreen].bounds);
        }
        self.maximumLeftDrawerWidth = width;
    }
}

- (void)openDrawerSide:(MMDrawerSide)drawerSide animated:(BOOL)animated velocity:(CGFloat)velocity animationOptions:(UIViewAnimationOptions)options completion:(void (^)(BOOL))completion
{
    [super openDrawerSide:drawerSide animated:animated velocity:velocity animationOptions:options completion:completion];
    UIViewController *centerVC = ((UINavigationController*)self.centerViewController).topViewController;
    [[NSNotificationCenter defaultCenter] removeObserver:centerVC name:@"NetworkSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:centerVC name:@"NetworkError" object:nil];
    UIViewController *leftTopVC = ((UINavigationController*)self.leftDrawerViewController).topViewController;
    [[NSNotificationCenter defaultCenter] addObserver:leftTopVC selector:@selector(networkSuccess:) name:@"NetworkSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:leftTopVC selector:@selector(networkError:) name:@"NetworkError" object:nil];
    self.articleListController.tableView.scrollsToTop = NO;
    self.feedListController.tableView.scrollsToTop = YES;
}

- (void)closeDrawerAnimated:(BOOL)animated velocity:(CGFloat)velocity animationOptions:(UIViewAnimationOptions)options completion:(void (^)(BOOL))completion
{
    [super closeDrawerAnimated:animated velocity:velocity animationOptions:options completion:completion];
    [((UINavigationController*)self.leftDrawerViewController).viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
        [[NSNotificationCenter defaultCenter] removeObserver:vc name:@"NetworkSuccess" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:vc name:@"NetworkError" object:nil];
    }];
    UIViewController *centerVC = ((UINavigationController*)self.centerViewController).topViewController;
    [[NSNotificationCenter defaultCenter] addObserver:centerVC selector:@selector(networkSuccess:) name:@"NetworkSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:centerVC selector:@selector(networkError:) name:@"NetworkError" object:nil];
    self.articleListController.tableView.scrollsToTop = YES;
    self.feedListController.tableView.scrollsToTop = NO;
}

@end
