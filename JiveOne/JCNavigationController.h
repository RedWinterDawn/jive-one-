//
//  JCDropdownNavigationViewController.h
//  NavigationControllerTestbed
//
//  Created by Robert Barclay on 2/6/15.
//  Copyright (c) 2015 JiveCommunications. All rights reserved.
//

@import UIKit;

#define JC_NAVIGATION_CONTROLLER_SLIDE_ANIMATION_DURATION 0.5

@interface JCNavigationController : UINavigationController

// State Properties
@property (nonatomic, readonly, getter=isShowingDropdown) BOOL showingDropdown;
@property (nonatomic, readonly, getter=isShowingShutter) BOOL showingShutter;

// Dropdown
-(void)presentDropdownViewController:(UIViewController *)viewController
                   leftBarButtonItem:(UIBarButtonItem *)leftBarButtonItem
                  rightBarButtonItem:(UIBarButtonItem *)rightBarButtonItem
                           maxHeight:(CGFloat)maxHeight
                            animated:(BOOL)animated;

-(void)dismissDropdownViewControllerAnimated:(BOOL)animated
                                  completion:(void (^)(void))completion;

-(IBAction)closeDropdown:(id)sender;

@end

@interface UIViewController (JCNavigationViewController)

@property(nonatomic, strong, readonly) JCNavigationController *jc_navigationController;

// Dropdown
-(void)presentDropdownViewController:(UIViewController *)viewController
                            animated:(BOOL)animated;

-(void)presentDropdownViewController:(UIViewController *)viewController
                           maxHeight:(CGFloat)maxHeight
                            animated:(BOOL)animated;

-(void)presentDropdownViewController:(UIViewController *)viewController
                   leftBarButtonItem:(UIBarButtonItem *)leftBarButtonItem
                  rightBarButtonItem:(UIBarButtonItem *)rightBarButtonItem
                           maxHeight:(CGFloat)maxHeight
                            animated:(BOOL)animated;

@end