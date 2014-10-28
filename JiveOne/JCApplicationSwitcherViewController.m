//
//  JCApplicationSwitcherViewController.m
//  JCApplicationSwitcher
//
//  Created by Robert Barclay on 10/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApplicationSwitcherViewController.h"

@interface JCApplicationSwitcherViewController () <UITableViewDataSource, UITableViewDelegate>
{
    NSArray *_viewControllers;                          // Array of available tab view controllers
    UIViewController *_selectedViewController;
    UIViewController *_transitionViewController;
    
    UINavigationController *_menuNavigationController;
    UITableViewController *_menuTableViewController;
    
    UIViewController *_activityViewController;
    
    bool _showingMenu;
}

@end

@implementation JCApplicationSwitcherViewController

/**
 * Override to retreive the child view controllers loaded from the nib, and ensure that they are stored in a local 
 * array, but not attached as children view controllers yet.
 */
-(void)awakeFromNib
{
    // grab the view controllers, which were loaded by the nib and put them into an array. if the data source has method
    // implemented, give it a chance to the data source to re-order the pages, or add and remove any before they get
    // fully read and populated as child view controllers.
    NSArray *viewControllers = super.viewControllers;
    if (self.delegate && [self.delegate respondsToSelector:@selector(applicationSwitcherController:willLoadViewControllers:)])
        viewControllers = [self.delegate applicationSwitcherController:self willLoadViewControllers:viewControllers];
    
    _viewControllers = viewControllers;
    
    // Since we are taking chanrge of these view controllers, and storing in the array, we remove them as child view
    // controllers from thier parent, which happens to be us. We will manually control them, adding the as child view
    // controllers as we navigate between them.
    for (UIViewController *viewController in _viewControllers)
        [viewController removeFromParentViewController];
}

/**
 * Override to provide custom view hierarchy. We provide an new clean base view, create instances of the top table view 
 * controller and activity controller, linking them to us.
 *
 * The left drawer view controller acts as the tab bar "menu" controller and the
 * center view controller acts as the transistion view whos size and movement is
 * controlled by the draw controller. When a tab is selected from the menu, when
 * handle the addition and removeal of that tab controller to the center view
 * controller.
 */
-(void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
    view.autoresizesSubviews = true;
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    // Create the transition view.
    _transitionViewController = [[UIViewController alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
    [super addChildViewController:_transitionViewController];
    [view addSubview:_transitionViewController.view];
    
    // Instance the menu view controller
    UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:self.menuViewControllerStoryboardIdentifier];
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        _menuNavigationController = (UINavigationController *)viewController;
        viewController = _menuNavigationController.topViewController;
        if ([viewController isKindOfClass:[UITableViewController class]]) {
            _menuTableViewController = (UITableViewController *)viewController;
            _menuTableViewController.tableView.dataSource = self;
            _menuTableViewController.tableView.delegate = self;
        }
    }
    [super addChildViewController:_menuNavigationController];
    [view addSubview:_menuNavigationController.view];
    
    // Instance the activity view controller
    _activityViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.activityViewControllerStoryboardIdentifier];
    [super addChildViewController:_activityViewController];
    [view addSubview:_activityViewController.view];
    
    self.view = view;
}

/**
 * Iterate over each of the child view controllers and set a menu button to any navigation view controllers. Can be 
 * either a UIButton or a UIBarButtonItem subclass.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //[self addMenuBarButtonItemToViewController:_menuNavigationController];
    
    [self hideMenuAnimated:NO];
    for (UIViewController *viewController in _viewControllers)
        [self addMenuBarButtonItemToViewController:viewController];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGRect navBarFrame = _menuNavigationController.navigationBar.frame;
    CGFloat tableHeight = navBarFrame.size.height + (57 * _viewControllers.count);
    CGRect frame = self.view.bounds;
    CGFloat viewHeight = frame.size.height;
    frame.size.height = tableHeight;
    _menuNavigationController.view.frame = frame;
    
    frame.size.height = viewHeight - tableHeight;
    frame.origin.y = tableHeight;
    _activityViewController.view.frame = frame;
}

-(void)addMenuBarButtonItemToViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        viewController = [navigationController.viewControllers lastObject];
        
        UIBarButtonItem *menuBarButtonItem;
        if (self.delegate && [self.delegate respondsToSelector:@selector(applicationSwitcherController:identifier:)]) {
            menuBarButtonItem = [self.delegate applicationSwitcherController:self identifier:viewController.restorationIdentifier];
            viewController.navigationItem.leftBarButtonItem = menuBarButtonItem;
        }
    }
    else if ([viewController isKindOfClass:[UITabBarController class]])
    {
        UITabBarController *tabBarController = (UITabBarController *)viewController;
        NSArray *viewControllers = tabBarController.viewControllers;
        for (UIViewController *viewController in viewControllers) {
            [self addMenuBarButtonItemToViewController:viewController];
        }
        
    }
}

#pragma mark - IBAction -

-(IBAction)showMenu:(id)sender
{
    if (_showingMenu) {
        [self hideMenuAnimated:YES];
    }
    else {
        [self showMenuAnimated:YES];
    }
}

#pragma mark - Setters -

-(void)setSelectedViewController:(UIViewController *)selectedViewController
{
    if (_selectedViewController == selectedViewController)
        return;
    
    // When first loading, ask the dataSource if we have a saved view controller;
    if (_selectedViewController == nil && selectedViewController == nil && self.delegate && [self.delegate respondsToSelector:@selector(applicationSwitcherLastSelectedViewController:)])
        selectedViewController = [self.delegate applicationSwitcherLastSelectedViewController:self];
    
    [self transitionFromViewController:_selectedViewController
                      toViewController:selectedViewController
                              duration:0
                               options:UIViewAnimationOptionAllowAnimatedContent
                            animations:^{
                                
                            }
                            completion:^(BOOL finished) {
                                _selectedViewController = selectedViewController;
                                if (self.delegate && [self.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)])
                                    [self.delegate tabBarController:self didSelectViewController:selectedViewController];
                            }];
}

-(void)setSelectedIndex:(NSUInteger)selectedIndex
{
    UIViewController *viewControllerToSelect = [_viewControllers objectAtIndex:selectedIndex];
    self.selectedViewController = viewControllerToSelect;
}

#pragma mark - Getters -

-(NSArray *)viewControllers
{
    if (_viewControllers)
        return _viewControllers;
    return super.viewControllers;
}

-(UIViewController *)selectedViewController
{
    return _selectedViewController;
}

-(NSUInteger)selectedIndex
{
    return [self.viewControllers indexOfObject:self.selectedViewController];
}

#pragma mark - Private -

-(void)showMenuAnimated:(bool)animated
{
    CGRect menuFrame = _menuNavigationController.view.frame;
    menuFrame.origin.y = 0;
    
    CGRect activityFrame = _activityViewController.view.frame;
    activityFrame.origin.y = menuFrame.origin.y + menuFrame.size.height;
    
    [UIView animateWithDuration:(animated ? 0.3 : 0)
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _menuNavigationController.view.frame = menuFrame;
                         _activityViewController.view.frame = activityFrame;
                         _transitionViewController.view.alpha = 0.2;
                     }
                     completion:^(BOOL finished) {
                         _showingMenu = true;
                     }];
}

-(void)hideMenuAnimated:(bool)animated
{
    CGRect menuFrame = _menuNavigationController.view.frame;
    menuFrame.origin.y = -menuFrame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height;
    
    CGRect activityFrame = _activityViewController.view.frame;
    activityFrame.origin.y = 2 * (menuFrame.origin.y + menuFrame.size.height + activityFrame.size.height);
    [UIView animateWithDuration:(animated ? 0.3 : 0)
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _menuNavigationController.view.frame = menuFrame;
                         _activityViewController.view.frame = activityFrame;
                         _transitionViewController.view.alpha = 1;
                     }
                     completion:^(BOOL finished) {
                         _showingMenu = false;
                     }];
}


/**
 * Handles the transition of one view controller to anouther view controller.
 */
-(void)transitionFromViewController:(UIViewController *)fromViewController
                   toViewController:(UIViewController *)toViewController
                           duration:(NSTimeInterval)duration
                            options:(UIViewAnimationOptions)options
                         animations:(void (^)(void))animations
                         completion:(void (^)(BOOL))completion
{
    // if there is not toViewController, there is no need to transition.
    if (!toViewController)
        return;
    
    UIViewController *controller = _transitionViewController;
    [UIView animateWithDuration:duration
                          delay:0
                        options:options
                     animations:^{
                         [fromViewController.view removeFromSuperview];
                         [controller.view addSubview:toViewController.view];
                         animations();
                     }
                     completion:^(BOOL finished) {
                         [fromViewController removeFromParentViewController];
                         [controller addChildViewController:toViewController];
                         completion(true);
                     }];
}

/**
 * Returns a Table View Cell for a given Tab Bar Item. Called from the
 * UITableViewDataSource delegate handler for the section designated by the
 * controllers data source as the menu section.
 */
-(UITableViewCell *)tableView:(UITableView *)tableView cellForTabBarItem:(UITabBarItem *)tabBarItem identifier:(NSString *)identifier
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(applicationSwitcherController:tableView:cellForTabBarItem:identifier:)]) {
        return [self.delegate applicationSwitcherController:self tableView:tableView cellForTabBarItem:tabBarItem identifier:identifier];
    }
    
    static NSString *resueIdentifier = @"MenuCell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:resueIdentifier];
    cell.textLabel.text = tabBarItem.title;
    cell.imageView.image = tabBarItem.image;
    return cell;
}

#pragma mark - Delegate Handlers -

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.viewControllers count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *viewController = [self.viewControllers objectAtIndex:indexPath.row];
    return [self tableView:tableView cellForTabBarItem:viewController.tabBarItem identifier:viewController.restorationIdentifier];
}

#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *viewController = [self.viewControllers objectAtIndex:indexPath.row];
    bool shouldShow = TRUE;
    if (self.delegate && [self.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
        shouldShow = [self.delegate tabBarController:self shouldSelectViewController:viewController];
    }

    if (!shouldShow)
    {
        return;
    }
    
    self.selectedViewController = viewController;
    [self hideMenuAnimated:YES];
}

@end
