//
//  JCApplicationSwitcherViewController.m
//  JCApplicationSwitcher
//
//  Created by Robert Barclay on 10/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApplicationSwitcherViewController.h"

#import "JCRecentEventsTableViewController.h"
#import "JCStoryboardLoaderViewController.h"
#import "JCDrawerController.h"
#import "JCDrawerVisualStateManager.h"
#import "JCAppMenuViewController.h"

@interface JCApplicationSwitcherViewController () <UITableViewDataSource, UITableViewDelegate, JCRecentEventsTableViewControllerDelegate>
{
    NSArray *_viewControllers;                          // Array of available tab view controllers
    UIViewController *_selectedViewController;          // Currently Selected View Controller
    JCDrawerController *_drawerController;              // Base Drawer View Controller;
    JCAppMenuViewController *_appMenuViewController;
    UIViewController *_transitionViewController;
    BOOL _showingMenu;                                  // Menu state flag
}

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
    
    // Transistion View Controller.
    _transitionViewController = [[UIViewController alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
    _transitionViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _transitionViewController.view.autoresizesSubviews = TRUE;
    [_transitionViewController.view setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    // Menu View Controller
    UIViewController *menuViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.menuViewControllerStoryboardIdentifier];
    if ([menuViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)menuViewController;
        navigationController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [navigationController.view setTranslatesAutoresizingMaskIntoConstraints:YES];
        UIViewController *viewController = navigationController.topViewController;
        if ([viewController isKindOfClass:[JCAppMenuViewController class]]) {
            _appMenuViewController = (JCAppMenuViewController *)viewController;
            _appMenuViewController.menuTableViewDataSource = self;
            _appMenuViewController.menuTableViewDelegate = self;
            _appMenuViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [_appMenuViewController.view setTranslatesAutoresizingMaskIntoConstraints:YES];
            
            _appMenuViewController.recentEventsTableViewController.delegate = self;
        }
    }
    
    // Drawer Controller
    _drawerController = [[JCDrawerController alloc] initWithCenterViewController:_transitionViewController leftDrawerViewController:menuViewController];
    _drawerController.openDrawerGestureModeMask = MMOpenDrawerGestureModeNone;
    _drawerController.closeDrawerGestureModeMask = MMOpenDrawerGestureModeAll;
    _drawerController.view.frame = view.bounds;
    
    [_drawerController setDrawerVisualStateBlock:^(MMDrawerController *drawerController, MMDrawerSide drawerSide, CGFloat percentVisible) {
        MMDrawerControllerDrawerVisualStateBlock block;
        block = [[JCDrawerVisualStateManager sharedManager] drawerVisualStateBlockForDrawerSide:drawerSide];
        if(block)
            block(drawerController, drawerSide, percentVisible);
    }];

    [super addChildViewController:_drawerController];
    [view addSubview:_drawerController.view];
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
            }
            else {
                self.selectedViewController = [_viewControllers firstObject];
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
    _drawerController.maximumLeftDrawerWidth = self.view.bounds.size.width - 50;
    
    CGSize size = _appMenuViewController.menuTableViewController.tableView.contentSize;
    _appMenuViewController.appMenuHeightConstraint.constant = size.height;
}

#pragma mark - IBAction -

-(IBAction)showMenu:(id)sender
{
    [_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:NULL];
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
    if ([viewController isKindOfClass:[JCStoryboardLoaderViewController class]]) {
        viewController = ((JCStoryboardLoaderViewController *)viewController).embeddedViewController;
    }
    
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
    
    UIViewController *transitionViewController = _transitionViewController;
    [UIView animateWithDuration:duration
                          delay:0
                        options:options
                     animations:^{
                         [fromViewController removeFromParentViewController];
                         [fromViewController.view removeFromSuperview];
                         toViewController.view.frame = transitionViewController.view.bounds;
                         [transitionViewController addChildViewController:toViewController];
                         [transitionViewController.view addSubview:toViewController.view];
                         
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
    [_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:NULL];
}

#pragma mark JCRecentLineEventsTableViewControllerDelegate

-(void)recentEventController:(JCRecentLineEventsTableViewController *)controller didSelectObject:(id)object
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(applicationSwitcher:shouldNavigateToRecentEvent:)]) {
        [self.delegate applicationSwitcher:self shouldNavigateToRecentEvent:object];
        [_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:NULL];
    }
}

@end
