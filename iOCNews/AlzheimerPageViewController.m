#import "AlzheimerPageViewController.h"

@interface AlzheimerPageViewController () {
    UIPageViewControllerTransitionStyle _transitionStyle;
    UIPageViewControllerNavigationOrientation _navigationOrientation;
}

@end

@implementation AlzheimerPageViewController

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    return [self initWithTransitionStyle: UIPageViewControllerTransitionStyleScroll
                   navigationOrientation: UIPageViewControllerNavigationOrientationHorizontal
                                 options: nil];
}

- (instancetype) initWithTransitionStyle: (UIPageViewControllerTransitionStyle) transitionStyle navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options {
    NSParameterAssert(transitionStyle == UIPageViewControllerTransitionStyleScroll);
    
    self = [super init];
    
    if( self ) {
        _transitionStyle = transitionStyle;
        _navigationOrientation = navigationOrientation;
    }
    return self;
}

- (void) setViewControllers: (NSArray*) viewControllers direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    NSParameterAssert(viewControllers.count == 1);
    UIViewController* newViewController = viewControllers.lastObject;
    
    NSParameterAssert(self.viewControllers.count <= 1);
    UIViewController* oldViewController = self.viewControllers.lastObject;
    
    [newViewController willMoveToParentViewController: self];
    [self addChildViewController: newViewController];
    [newViewController didMoveToParentViewController: self];
    
    if( self.isViewLoaded ) {
        
        [newViewController beginAppearanceTransition: YES animated: animated];
        
        if( [self.delegate respondsToSelector:@selector(pageViewController:willTransitionToViewControllers:)])
            [self.delegate pageViewController: (UIPageViewController*)self
              willTransitionToViewControllers: @[newViewController]];
        
        if( oldViewController ) {
            
            CGRect newFrame = self.view.bounds;
            if( direction == UIPageViewControllerNavigationDirectionForward ) {
                if( _navigationOrientation == UIPageViewControllerNavigationOrientationHorizontal ) {
                    newFrame.origin.x += CGRectGetWidth(self.view.bounds);
                }
                else {
                    newFrame.origin.y -= CGRectGetHeight(self.view.bounds);
                }
            }
            else {
                if( _navigationOrientation == UIPageViewControllerNavigationOrientationHorizontal ) {
                    newFrame.origin.x -= CGRectGetWidth(self.view.bounds);
                }
                else {
                    newFrame.origin.y += CGRectGetHeight(self.view.bounds);
                }
            }
            
            newViewController.view.frame = newFrame;
            
            [self transitionFromViewController: oldViewController
                              toViewController: newViewController
                                      duration: [self animationDuration] * animated
                                       options: UIViewAnimationOptionCurveEaseOut
                                    animations: ^{
                                        CGRect oldFrame = oldViewController.view.frame;
                                        CGRect newFrame = oldFrame;
                                        
                                        if( direction == UIPageViewControllerNavigationDirectionForward ) {
                                            if( _navigationOrientation == UIPageViewControllerNavigationOrientationHorizontal ) {
                                                oldFrame.origin.x -= CGRectGetWidth(self.view.bounds);
                                            }
                                            else {
                                                oldFrame.origin.y += CGRectGetHeight(self.view.bounds);
                                            }
                                        }
                                        else {
                                            if( _navigationOrientation == UIPageViewControllerNavigationOrientationHorizontal ) {
                                                oldFrame.origin.x += CGRectGetWidth(self.view.bounds);
                                            }
                                            else {
                                                oldFrame.origin.y -= CGRectGetHeight(self.view.bounds);
                                            }
                                        }
                                        
                                        oldViewController.view.frame = oldFrame;
                                        newViewController.view.frame = newFrame;
                                        
                                    } completion:^(BOOL finished) {
                                        [newViewController endAppearanceTransition];
                                        
                                        if( [self.delegate respondsToSelector: @selector(pageViewController:didFinishAnimating:previousViewControllers:transitionCompleted:)] ) {
                                            [self.delegate pageViewController: (UIPageViewController*)self
                                                           didFinishAnimating: YES
                                                      previousViewControllers: @[oldViewController]
                                                          transitionCompleted: YES];
                                        }
                                        
                                        [oldViewController removeFromParentViewController];
                                    }];
        }
        else {
            //First time -> animation is different
            newViewController.view.frame = self.view.bounds;


            
            
            [UIView transitionWithView: self.view
                              duration: [self animationDuration] * animated
                               options: UIViewAnimationOptionCurveEaseOut
                            animations: ^{
                                [self.view addSubview: newViewController.view];
                                newViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
                                
                                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:newViewController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
                                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:newViewController.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
                                
                                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:newViewController.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
                                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:newViewController.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
                            } completion: ^(BOOL finished) {
                                [newViewController endAppearanceTransition];
                                
                                if( [self.delegate respondsToSelector: @selector(pageViewController:didFinishAnimating:previousViewControllers:transitionCompleted:)] ) {
                                    [self.delegate pageViewController: (UIPageViewController*)self
                                                   didFinishAnimating: YES
                                              previousViewControllers: nil  //No previous controller
                                                  transitionCompleted: YES];
                                }
                            }];
        }
    }
    else {
        NSLog(@"%@ set view controllers but the view was not loaded", NSStringFromClass(self.class));
    }
}

- (NSArray*) viewControllers {
    NSArray* children = self.childViewControllers;
    NSParameterAssert(children.count <= 2); //0: empty, 1: static, 2:transitioning
    return children;
}

- (NSArray*) gestureRecognizers {
    return [self.view.gestureRecognizers filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"SELF isKindOfClass: %@", [UISwipeGestureRecognizer class]]];
}
                 
- (NSTimeInterval) animationDuration {
    return [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
}

#pragma mark - UIViewController
- (void) viewDidLoad {
    [super viewDidLoad];
    
    UISwipeGestureRecognizer* swipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget: self
                                                                                                 action: @selector(viewWasSwiped:)];
    swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer: swipeLeftGestureRecognizer];
    
    UISwipeGestureRecognizer* swipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget: self
                                                                                                     action: @selector(viewWasSwiped:)];
    swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer: swipeRightGestureRecognizer];
    
    if( self.viewControllers.count ) {
        NSParameterAssert(self.viewControllers.count == 1);
        
        UIViewController* newViewController = self.viewControllers.lastObject;
        newViewController.view.frame = self.view.bounds;
        
        [self.view addSubview: newViewController.view];
        newViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:newViewController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:newViewController.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:newViewController.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:newViewController.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    }
}

#pragma mark - Actions
- (IBAction) viewWasSwiped: (UISwipeGestureRecognizer*)sender {
    
    UIViewController* oldViewController = self.viewControllers.lastObject;
    UIViewController* newViewController = nil;
    UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionForward;
    
    switch (sender.direction) {
        case UISwipeGestureRecognizerDirectionRight:
        {
            newViewController = [self.dataSource pageViewController: (UIPageViewController*)self
                                 viewControllerBeforeViewController: oldViewController];
            direction = UIPageViewControllerNavigationDirectionReverse;
            break;
        }
        case UISwipeGestureRecognizerDirectionLeft:
        {
            newViewController = [self.dataSource pageViewController: (UIPageViewController*)self
                                  viewControllerAfterViewController: oldViewController];
            break;
        }
        default:
            break;
    }
    
    if( newViewController ) {
        [newViewController willMoveToParentViewController: self];
        [self addChildViewController: newViewController];
        [newViewController didMoveToParentViewController: self];
        
        [newViewController beginAppearanceTransition: YES animated: YES];
        
        CGRect newFrame = self.view.bounds;
        if( direction == UIPageViewControllerNavigationDirectionForward ) {
            if( _navigationOrientation == UIPageViewControllerNavigationOrientationHorizontal ) {
                newFrame.origin.x += CGRectGetWidth(self.view.bounds);
            }
            else {
                newFrame.origin.y -= CGRectGetHeight(self.view.bounds);
            }
        }
        else {
            if( _navigationOrientation == UIPageViewControllerNavigationOrientationHorizontal ) {
                newFrame.origin.x -= CGRectGetWidth(self.view.bounds);
            }
            else {
                newFrame.origin.y += CGRectGetHeight(self.view.bounds);
            }
        }
        
        newViewController.view.frame = newFrame;
        newViewController.view.alpha = 0.f;
        
        if( [self.delegate respondsToSelector:@selector(pageViewController:willTransitionToViewControllers:)])
            [self.delegate pageViewController: (UIPageViewController*)self
              willTransitionToViewControllers: @[newViewController]];
        
        [self transitionFromViewController: oldViewController
                          toViewController: newViewController
                                  duration: [self animationDuration]
                                   options: UIViewAnimationOptionCurveEaseOut
                                animations: ^{
                                    CGRect oldFrame = oldViewController.view.frame;
                                    CGRect newFrame = oldFrame;
                                    
                                    if( direction == UIPageViewControllerNavigationDirectionForward ) {
                                        if( _navigationOrientation == UIPageViewControllerNavigationOrientationHorizontal ) {
                                            oldFrame.origin.x -= CGRectGetWidth(self.view.bounds);
                                        }
                                        else {
                                            oldFrame.origin.y += CGRectGetHeight(self.view.bounds);
                                        }
                                    }
                                    else {
                                        if( _navigationOrientation == UIPageViewControllerNavigationOrientationHorizontal ) {
                                            oldFrame.origin.x += CGRectGetWidth(self.view.bounds);
                                        }
                                        else {
                                            oldFrame.origin.y -= CGRectGetHeight(self.view.bounds);
                                        }
                                    }
 
                                    oldViewController.view.frame = oldFrame;
                                    newViewController.view.frame = newFrame;
                                    oldViewController.view.alpha = 0.f;
                                    newViewController.view.alpha = 1.f;
                                } completion:^(BOOL finished) {
                                    NSParameterAssert(oldViewController.view.superview == nil);
                        
                                    [newViewController endAppearanceTransition];
                                    [oldViewController removeFromParentViewController];
                                    
                                    if( [self.delegate respondsToSelector: @selector(pageViewController:didFinishAnimating:previousViewControllers:transitionCompleted:)] ) {
                                        [self.delegate pageViewController: (UIPageViewController*)self
                                                       didFinishAnimating: YES
                                                  previousViewControllers: @[oldViewController]
                                                      transitionCompleted: YES];
                                    }
                                }];

    }
}

@end
