//
//  JCDropdownNavigationViewController.m
//  NavigationControllerTestbed
//
//  Created by Robert Barclay on 2/6/15.
//  Copyright (c) 2015 JiveCommunications. All rights reserved.
//

#import "JCNavigationController.h"

@interface JCNavigationController () {
    UIViewController *_dropdownViewController;
    UINavigationBar *_overlayNavigationBar;
    
    UIViewController *_shutterTopViewController;
    UIViewController *_shutterBottomViewController;
}

@end

@implementation JCNavigationController

#pragma mark - Dropdown -

-(void)presentDropdownViewController:(UIViewController *)viewController
                   leftBarButtonItem:(UIBarButtonItem *)leftBarButtonItem
                  rightBarButtonItem:(UIBarButtonItem *)rightBarButtonItem
                           maxHeight:(CGFloat)maxHeight
                            animated:(BOOL)animated
{
    if (_showingDropdown) {
        return;
    }
    
    // Calculate the frame of the view controller. Since it will be animated it, we calulate it to
    // be off screen, and then we animate it to be on screen lower.
    CGRect bounds = self.view.bounds;
    CGRect navBarBounds = self.navigationBar.frame;
    CGFloat y = -bounds.size.height + navBarBounds.size.height;
    CGFloat height = MIN(maxHeight, bounds.size.height - navBarBounds.size.height - navBarBounds.origin.y);
    CGRect frame = CGRectMake(0, y, bounds.size.width, height);
    viewController.view.frame = frame;
    
    // Add the view controller
    [self addChildViewController:viewController];
    [self.view addSubview:viewController.view];
    [self.view bringSubviewToFront:self.navigationBar];
    
    // Add an overlay Navigation Bar with dismiss controls.
    _overlayNavigationBar = [JCNavigationController navigationBarForTitle:[JCNavigationController titleForViewController:viewController]
                                                        leftBarButtonItem:leftBarButtonItem
                                                       rightBarButtonItem:rightBarButtonItem
                                                                    frame:self.navigationBar.frame];
    _overlayNavigationBar.alpha = 0;
    _overlayNavigationBar.backgroundColor = self.navigationBar.backgroundColor;
    _overlayNavigationBar.translucent = self.navigationBar.translucent;
    _overlayNavigationBar.tintColor = self.navigationBar.tintColor;
    _overlayNavigationBar.tintAdjustmentMode = self.navigationBar.tintAdjustmentMode;
    
    [self.view addSubview:_overlayNavigationBar];
    
    // Calculate the animated end positon of the view controller and animate in.
    frame.origin.y = navBarBounds.size.height + navBarBounds.origin.y;
    [UIView animateWithDuration:(animated ? JC_NAVIGATION_CONTROLLER_SLIDE_ANIMATION_DURATION : 0)
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         viewController.view.frame = frame;
                         _overlayNavigationBar.alpha = 1;
                     } completion:^(BOOL finished) {
                         _showingDropdown = YES;
                         _dropdownViewController = viewController;
                     }];
}

-(void)dismissDropdownViewControllerAnimated:(BOOL)animated
                                  completion:(void (^)(void))completion
{
    
    if (!_showingDropdown) {
        return;
    }
    
    // Get the frame of the dropdown controller and calculate the new frame to animate off screen.
    // Animate off screen and release all attachement to it. Notify caller of completion.
    CGRect frame = _dropdownViewController.view.frame;
    frame.origin.y = -self.view.bounds.size.height;
    [UIView animateWithDuration:(animated ? JC_NAVIGATION_CONTROLLER_SLIDE_ANIMATION_DURATION : 0)
                     animations:^{
                         _dropdownViewController.view.frame = frame;
                         _overlayNavigationBar.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         _showingDropdown = NO;
                         
                         [_dropdownViewController.view removeFromSuperview];
                         [_dropdownViewController removeFromParentViewController];
                         _dropdownViewController = nil;
                         
                         [_overlayNavigationBar removeFromSuperview];
                         _overlayNavigationBar = nil;
                         
                         if (completion) {
                             completion();
                         }
                     }];
}

-(IBAction)closeDropdown:(id)sender
{
    [self dismissDropdownViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Private -

/**
 *  Utility method for creating a basic navigation bar
 */
+ (UINavigationBar *)navigationBarForTitle:(NSString *)title leftBarButtonItem:(UIBarButtonItem *)leftBarButtonItem rightBarButtonItem:(UIBarButtonItem *)rightBarButtonItem frame:(CGRect)frame {
    // Create a nav bar to go over the top of of the current nav bar.
    UINavigationBar *bar = [[UINavigationBar alloc] initWithFrame:frame];
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:title];
    if (leftBarButtonItem) {
        item.leftBarButtonItem = leftBarButtonItem;
    }
    if (rightBarButtonItem) {
        item.rightBarButtonItem = rightBarButtonItem;
    }
    
    [bar pushNavigationItem:item animated:NO];
    return bar;
}

+ (NSString *)titleForViewController:(UIViewController *)viewController
{
    // Get the title from the view controller.
    if (viewController.navigationItem && viewController.navigationItem.title) {
        return viewController.navigationItem.title;
    }
    return viewController.title;
}

@end

#pragma mark - UIViewController Category -

@implementation UIViewController (JCDNavigationViewController)

-(JCNavigationController *)jc_navigationController
{
    UIViewController *parentViewController = self.parentViewController;
    while (parentViewController != nil) {
        if([parentViewController isKindOfClass:[JCNavigationController class]]){
            return (JCNavigationController *)parentViewController;
        }
        parentViewController = parentViewController.parentViewController;
    }
    return nil;
}

#pragma mark - Dropdown -

-(void)presentDropdownViewController:(UIViewController *)viewController
                            animated:(BOOL)animated
{
    JCNavigationController *navController = self.jc_navigationController;
    [self presentDropdownViewController:viewController
                              maxHeight:(navController.view.bounds.size.height - navController.navigationBar.bounds.size.height)
                               animated:animated];
}

-(void)presentDropdownViewController:(UIViewController *)viewController
                           maxHeight:(CGFloat)maxHeight
                            animated:(BOOL)animated
{
    JCNavigationController *navController = self.jc_navigationController;
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:navController
                                                                           action:@selector(closeDropdown:)];
    
    [navController presentDropdownViewController:viewController
                               leftBarButtonItem:nil
                              rightBarButtonItem:close
                                       maxHeight:maxHeight
                                        animated:animated];
}

-(void)presentDropdownViewController:(UIViewController *)viewController
                   leftBarButtonItem:(UIBarButtonItem *)leftBarButtonItem
                  rightBarButtonItem:(UIBarButtonItem *)rightBarButtonItem
                           maxHeight:(CGFloat)maxHeight
                            animated:(BOOL)animated {
    [self.jc_navigationController presentDropdownViewController:viewController
                                              leftBarButtonItem:leftBarButtonItem
                                             rightBarButtonItem:rightBarButtonItem
                                                      maxHeight:maxHeight
                                                       animated:animated];
}

-(void)dismissDropdownViewControllerAnimated:(BOOL)animated
                                  completion:(void (^)(void))completion {
    [self.jc_navigationController dismissDropdownViewControllerAnimated:animated
                                                             completion:completion];
}

@end