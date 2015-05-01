//
//  JCApplicationSwitcherViewController.m
//  JCApplicationSwitcher
//
//  Created by Robert Barclay on 10/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApplicationSwitcherViewController.h"
#import "JCRecentEventsTableViewController.h"

@interface JCApplicationSwitcherViewController () <UITableViewDataSource, UITableViewDelegate, JCRecentEventsTableViewControllerDelegate>
{
    NSArray *_viewControllers;                          // Array of available tab view controllers
    UIViewController *_selectedViewController;
    UINavigationBar *_menuNavigationBar;
    UIView *_statusBarView;
    
    BOOL _showingMenu;
}

@property (nonatomic, strong) UIView *transitionView;
@property (nonatomic, strong) UIViewController *activityViewController;
@property (nonatomic, strong) UINavigationController *menuNavigationController;

@end

@implementation JCApplicationSwitcherViewController

@dynamic delegate;

/**
 * Override to retreive the child view controllers loaded from the nib, and ensure that they are stored in a local 
 * array, but not attached as children view controllers yet.
 */
-(void)awakeFromNib
{
    // Grab the view controllers, which were loaded by the nib and put them into an array. if the data source has method
    // implemented, give it a chance to the data source to re-order the pages, or add and remove any before they get
    // fully read and populated as child view controllers.
    NSArray *viewControllers = super.viewControllers;
    for (UIViewController *viewController in viewControllers)
        [self addMenuBarButtonItemToViewController:viewController];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(applicationSwitcherController:willLoadViewControllers:)])
        viewControllers = [self.delegate applicationSwitcherController:self willLoadViewControllers:viewControllers];
    
    _viewControllers = viewControllers;
}

/**
 * Override to provide custom view hierarchy. We provide an new clean base view.
 */
-(void)loadView
{
    CGRect frame = [UIApplication sharedApplication].keyWindow.frame;
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.autoresizesSubviews = true;
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view = view;
}

/**
 * Iterate over each of the child view controllers and set a menu button to any navigation view controllers. Can be 
 * either a UIButton or a UIBarButtonItem subclass.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setTranslatesAutoresizingMaskIntoConstraints:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    // If _selectedViewController is nil, it means we have not yet selected a view controller, and
    // are in our initial state. We need to ask our delegate if it has a last selected view
    // controller, and if that last selected view controller is different from the default view
    // controller being requested to be loaded. if it is different, we override to show the last
    // selected view controller. If the last selected view controller comes back null, it means we
    // need to load our default state.
    if (!_selectedViewController) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(applicationSwitcherLastSelectedViewController:)]) {
            UIViewController *lastSelectedViewController = [self.delegate applicationSwitcherLastSelectedViewController:self];
            if (lastSelectedViewController != nil) {
                self.selectedViewController = lastSelectedViewController;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideMenuAnimated:NO];
                });
            }
            else {
                self.selectedViewController = [_viewControllers firstObject];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showMenuAnimated:NO];
                });
            }
        }
    }
    else {
        [_selectedViewController viewWillAppear:animated];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_selectedViewController) {
        [_selectedViewController viewDidAppear:animated];
    }
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    UIView *transitionView = self.transitionView;
    transitionView.frame = self.view.bounds;
    if (transitionView.superview == nil) {
        [self.view addSubview:transitionView];
        [self.view sendSubviewToBack:transitionView];
    }
}

#pragma mark - IBAction -

-(IBAction)showMenu:(id)sender
{
    if (!_selectedViewController) {
        return;
    }
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
    // Ask the delegate permission to show the selected view controller.
    if (self.delegate && [self.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
        if (![self.delegate tabBarController:self shouldSelectViewController:selectedViewController]) {
            return;
        }
    }
    
    // Transition to the selected view controller.
    [self transitionFromViewController:_selectedViewController
                      toViewController:selectedViewController
                              duration:0
                               options:UIViewAnimationOptionAllowAnimatedContent
                            animations:NULL
                            completion:^(BOOL finished) {
                                if (finished)
                                {
                                    _selectedViewController = selectedViewController;
                                    if (self.delegate && [self.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)])
                                        [self.delegate tabBarController:self didSelectViewController:selectedViewController];
                                }
                            }];
}

-(void)setSelectedIndex:(NSUInteger)selectedIndex
{
    UIViewController *viewControllerToSelect = [_viewControllers objectAtIndex:selectedIndex];
    self.selectedViewController = viewControllerToSelect;
}

-(void)setViewControllers:(NSArray *)viewControllers
{
    _viewControllers = viewControllers;
}

-(void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
    _viewControllers = viewControllers;
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
    return [_viewControllers indexOfObject:_selectedViewController];
}

-(UIView *)transitionView
{
    if (!_transitionView) {
        _transitionView = [[UIView alloc] initWithFrame:CGRectZero];
        _transitionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _transitionView.autoresizesSubviews = TRUE;
        [_transitionView setTranslatesAutoresizingMaskIntoConstraints:YES];
    }
    return _transitionView;
}

-(UINavigationController *)menuNavigationController
{
    if (!_menuNavigationController) {
        UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:self.menuViewControllerStoryboardIdentifier];
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            _menuNavigationController = (UINavigationController *)viewController;
            _menuNavigationController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
            [_menuNavigationController.view setTranslatesAutoresizingMaskIntoConstraints:YES];
            [self addMenuBarButtonItemToViewController:_menuNavigationController];
            viewController = _menuNavigationController.topViewController;
            if ([viewController isKindOfClass:[UITableViewController class]]) {
                UITableViewController *menuTableViewController = (UITableViewController *)viewController;
                menuTableViewController.tableView.dataSource = self;
                menuTableViewController.tableView.delegate = self;
                menuTableViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [menuTableViewController.view setTranslatesAutoresizingMaskIntoConstraints:YES];
            }
        }
    }
    return _menuNavigationController;
}

-(UIViewController *)activityViewController
{
    if (!_activityViewController) {
        _activityViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.activityViewControllerStoryboardIdentifier];
        if ([_activityViewController isKindOfClass:[UINavigationController class]]) {
            UIViewController *controller = ((UINavigationController *)_activityViewController).topViewController;
            if ([controller isKindOfClass:[JCRecentEventsTableViewController class]]) {
                ((JCRecentEventsTableViewController *)controller).delegate = self;
            }
        }
    }
    return _activityViewController;
}

#pragma mark - Private -

/**
 * Takes a given view controller and asks the delegate for a menu button for that view.
 *
 * Checks to see if the view controller is a navigation controller, and adds it as the lefb bar 
 * button item. If the view controller is a tabBarController, it recursively goes through each of 
 * the tabBarViewController's child view controllers.
 */
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

-(void)showMenuAnimated:(bool)animated
{
    // Set the initial State
    UINavigationController *menuNavigationController = self.menuNavigationController;
    UITableView *tableView = ((UITableViewController *)menuNavigationController.topViewController).tableView;
    menuNavigationController.view.alpha = 0;
    menuNavigationController.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [menuNavigationController.view setTranslatesAutoresizingMaskIntoConstraints:YES];
    [self.view addSubview:menuNavigationController.view];
    [self addChildViewController:menuNavigationController];
    [menuNavigationController.view layoutIfNeeded];
    
    CGFloat standardStatusBarHeight = 20;
    CGFloat statusBarHeight = standardStatusBarHeight;
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    if (statusBarFrame.size.height > standardStatusBarHeight) {
        statusBarHeight = statusBarFrame.size.height - standardStatusBarHeight;
    }
    
    _menuNavigationBar = [[UINavigationBar alloc] initWithFrame:menuNavigationController.navigationBar.frame];
    _menuNavigationBar.translucent = menuNavigationController.navigationBar.translucent;
    _menuNavigationBar.tintColor = menuNavigationController.navigationBar.tintColor;
    _menuNavigationBar.backgroundColor = menuNavigationController.navigationBar.backgroundColor;
    _menuNavigationBar.barTintColor = menuNavigationController.navigationBar.barTintColor;
    [_menuNavigationBar setItems:@[menuNavigationController.topViewController.navigationItem]];
    _menuNavigationBar.frame = CGRectMake(0, statusBarHeight, _menuNavigationBar.bounds.size.width, _menuNavigationBar.bounds.size.height);
    [self.view addSubview:_menuNavigationBar];
    
    _statusBarView = [[UIView alloc] initWithFrame:[UIApplication sharedApplication].statusBarFrame];
    _statusBarView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [_statusBarView setTranslatesAutoresizingMaskIntoConstraints:YES];
    _statusBarView.backgroundColor = menuNavigationController.navigationBar.barTintColor;
    
    CGFloat h = standardStatusBarHeight;
    if (statusBarFrame.size.height > standardStatusBarHeight) {
        h = 0;
    }
    _statusBarView.frame = CGRectMake(0, 0, statusBarFrame.size.width, h);
    [self.view addSubview:_statusBarView];
    
    CGRect menuFrame = menuNavigationController.view.frame;
    CGRect navBarFrame = menuNavigationController.navigationBar.frame;
    CGFloat height = 0;
    if (![UIDevice iOS8]){
        height = statusBarHeight + navBarFrame.origin.y + navBarFrame.size.height + [tableView sizeThatFits:CGSizeMake(tableView.frame.size.width, FLT_MAX)].height;
    }
    else {
        height = navBarFrame.origin.y + navBarFrame.size.height + [tableView contentSize].height;
        if (statusBarFrame.size.height > standardStatusBarHeight) {
            height += standardStatusBarHeight;
        }
    }
    menuFrame.size.height = height;
    menuFrame.origin.y = self.view.frame.origin.y - menuFrame.size.height;
    menuNavigationController.view.frame = menuFrame;
    menuNavigationController.view.alpha = 1;
    
    // Calculate end state.
    
    if (![UIDevice iOS8]){
        menuFrame.origin.y = statusBarHeight;
    }
    else {
        menuFrame.origin.y = 0;
    }
    
    UIViewController *activityViewController = self.activityViewController;
    CGRect activityFrame = activityViewController.view.frame;
    activityFrame.size.height = self.view.bounds.size.height - menuFrame.size.height;
    activityFrame.origin.y = self.view.bounds.size.height;
    activityViewController.view.frame = activityFrame;
    [self addChildViewController:activityViewController];
    [self.view addSubview:activityViewController.view];
    
    activityFrame.origin.y = menuFrame.origin.y + menuFrame.size.height;
    
    
    // Animate.
    [_selectedViewController viewWillDisappear:animated];
    [UIView animateWithDuration:(animated ? 0.3 : 0)
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         menuNavigationController.view.frame = menuFrame;
                         activityViewController.view.frame = activityFrame;
                         if ([UIDevice iOS8])
                             self.transitionView.alpha = 0.2;
                     }
                     completion:^(BOOL finished) {
                         _showingMenu = true;
                         [_selectedViewController viewDidDisappear:animated];
                     }];
}

-(void)hideMenuAnimated:(bool)animated
{
    UINavigationController *menuNavigationController = self.menuNavigationController;
    UIViewController *activityViewController = self.activityViewController;
    CGRect menuFrame = menuNavigationController.view.frame;
    menuFrame.origin.y = -menuFrame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height;
    
    [_selectedViewController viewWillAppear:animated];
    
    CGRect activityFrame = activityViewController.view.frame;
    activityFrame.origin.y = self.view.bounds.size.height;
    [UIView animateWithDuration:(animated ? 0.3 : 0)
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         menuNavigationController.view.frame = menuFrame;
                         activityViewController.view.frame = activityFrame;
                         self.transitionView.alpha = 1;
                     }
                     completion:^(BOOL finished) {
                         _showingMenu = false;
                         [_selectedViewController viewDidAppear:animated];
                         
                         [menuNavigationController removeFromParentViewController];
                         [menuNavigationController.view removeFromSuperview];
                         self.menuNavigationController = nil;
                         
                         [_menuNavigationBar removeFromSuperview];
                         _menuNavigationBar = nil;
                         
                         [activityViewController removeFromParentViewController];
                         [activityViewController.view removeFromSuperview];
                         
                         [_statusBarView removeFromSuperview];
                         _statusBarView = nil;
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
    if (!toViewController)
        return;
    
    UIView *transitionView = self.transitionView;
    [UIView animateWithDuration:duration
                          delay:0
                        options:options
                     animations:^{
                         [fromViewController.view removeFromSuperview];
                         toViewController.view.frame = transitionView.bounds;
                         [transitionView addSubview:toViewController.view];
                         
                         if (animations) {
                             animations();
                         }
                     }
                     completion:^(BOOL finished) {
                         if (finished && completion) {
                             completion(finished);
                         }
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
        BOOL shouldShow = [self.delegate tabBarController:self shouldSelectViewController:viewController];
        if (!shouldShow) {
            return;
        }
    }

    self.selectedViewController = viewController;
    [self hideMenuAnimated:YES];
}

#pragma mark JCRecentLineEventsTableViewControllerDelegate

-(void)recentEventController:(JCRecentLineEventsTableViewController *)controller didSelectObject:(id)object
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(applicationSwitcher:shouldNavigateToRecentEvent:)]) {
        [self.delegate applicationSwitcher:self shouldNavigateToRecentEvent:object];
        [self hideMenuAnimated:YES];
    }
}

@end
