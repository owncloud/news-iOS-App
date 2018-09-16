//
//  PHArticleManagerController.m
//  iOCNews
//
//  Created by Peter Hedlund on 10/7/17.
//  Copyright © 2017 Peter Hedlund. All rights reserved.
//

#import "PHArticleManagerController.h"
#import "OCWebController.h"
#import "OCNewsHelper.h"
#import "AlzheimerPageViewController.h"

@interface PHArticleManagerController () <UIPageViewControllerDataSource>

@property (nonatomic, strong) AlzheimerPageViewController *pageViewController;

@end

@implementation PHArticleManagerController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.pageViewController.dataSource = self;
    
    if(self.articles.count)
    {
        NSArray *startingViewControllers = @[[self itemControllerForIndex:self.articleIndex]];
        [self.pageViewController setViewControllers:startingViewControllers
                                          direction:UIPageViewControllerNavigationDirectionForward
                                           animated:NO
                                         completion:nil];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"pageControllerEmbedSegue"]) {
        self.pageViewController = (AlzheimerPageViewController *)segue.destinationViewController;
        self.pageViewController.view.backgroundColor = [UIColor greenColor];
    }
}

#pragma mark UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    OCWebController *webController = (OCWebController *)viewController;
    
    if (webController.itemIndex > 0)
    {
        return [self itemControllerForIndex:webController.itemIndex-1];
    }
    
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    OCWebController *webController = (OCWebController *)viewController;
    
    if (webController.itemIndex + 1 < self.articles.count) {
        return [self itemControllerForIndex:webController.itemIndex + 1];
    }
    
    return nil;
}

- (OCWebController *)itemControllerForIndex:(NSUInteger)itemIndex
{
    if (itemIndex < self.articles.count) {
        OCWebController *webController = (OCWebController *)[self.storyboard instantiateViewControllerWithIdentifier:@"WebController"];
        webController.itemIndex = itemIndex;
        Item *currentItem = self.articles[itemIndex];
        webController.item = currentItem;
        if (currentItem.unreadValue) {
            currentItem.unreadValue = NO;
            [[OCNewsHelper sharedHelper] markItemsReadOffline:[NSMutableSet setWithObject:currentItem.myId]];
        }

        return webController;
    }
    
    return nil;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return self.articles.count;
}

@end
