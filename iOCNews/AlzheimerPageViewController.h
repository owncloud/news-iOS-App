#import <UIKit/UIKit.h>

@interface AlzheimerPageViewController : UIViewController

- (instancetype) initWithTransitionStyle: (UIPageViewControllerTransitionStyle) transitionStyle navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options;
- (void) setViewControllers: (NSArray*) viewControllers direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL))completion;

@property (nonatomic, weak) id<UIPageViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<UIPageViewControllerDelegate> delegate;
@property (nonatomic, readonly) NSArray* viewControllers;
@property (nonatomic, readonly) NSArray* gestureRecognizers;

@end