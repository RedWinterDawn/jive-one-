//
//  JCApplicationSwitcherViewController.m
//  JCApplicationSwitcher
//
//  Created by Robert Barclay on 10/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApplicationSwitcherViewController.h"
#import "JCRecentLineEventsTableViewController.h"

@interface JCApplicationSwitcherViewController () <UITableViewDataSource, UITableViewDelegate, JCRecentLineEventsTableViewControllerDelegate>
{
    NSArray *_viewControllers;                          // Array of available tab view controllers
    UIViewController *_selectedViewController;
    UIViewController *_transitionViewController;
    
    UINavigationController *_menuNavigationController;
    UITableViewController *_menuTableViewController;
    
    UIViewController *_activityViewController;
    
    BOOL _showingMenu;
}

@end

@implementation JCApplicationSwitcherViewController

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
    
    // Create the transition view. This will hold our child view controllers. We want it towards the
    // very back of the view subview stack.
    _transitionViewController = [[UIViewController alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
    [super addChildViewController:_transitionViewController];
    [view addSubview:_transitionViewController.view];
    
    // Instance the menu view controller.
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
    
    // Instance the activity view controller
    _activityViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.activityViewControllerStoryboardIdentifier];
    
    if ([_activityViewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *controller = ((UINavigationController *)_activityViewController).topViewController;
        if ([controller isKindOfClass:[JCRecentLineEventsTableViewController class]]) {
            ((JCRecentLineEventsTableViewController *)controller).delegate = self;
        }
    }
    self.view = view;
}

/**
 * Iterate over each of the child view controllers and set a menu button to any navigation view controllers. Can be 
 * either a UIButton or a UIBarButtonItem subclass.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addMenuBarButtonItemToViewController:_menuNavigationController];
    for (UIViewController *viewController in _viewControllers)
        [self addMenuBarButtonItemToViewController:viewController];
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
                [self hideMenuAnimated:NO];
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
    
    // Size the menu view controller.
    if(_menuNavigationController.view.superview == nil) {
        [super addChildViewController:_menuNavigationController];
        [self.view addSubview:_menuNavigationController.view];
        [_menuNavigationController.view layoutIfNeeded];
        CGRect navBarFrame = _menuNavigationController.navigationBar.frame;
        CGFloat tableHeight = [UIApplication sharedApplication].statusBarFrame.size.height + navBarFrame.origin.y + navBarFrame.size.height + [_menuTableViewController.tableView contentSize].height;
        
        // @!^$#$ Apple! Seriously!
        if (![UIDevice iOS8]) {
            CGSize textViewSize = [_menuTableViewController.tableView sizeThatFits:CGSizeMake(_menuTableViewController.tableView.frame.size.width, FLT_MAX)];
            tableHeight = [UIApplication sharedApplication].statusBarFrame.size.height + navBarFrame.origin.y + navBarFrame.size.height + textViewSize.height;
        }
        
        CGRect frame = self.view.bounds;
        frame.size.height = tableHeight;
        _menuNavigationController.view.frame = frame;
        _menuNavigationController.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
        _showingMenu = TRUE;
    }
    
    // Size the Activity View controller.
    if (_activityViewController.view.superview == nil) {
        [super addChildViewController:_activityViewController];
        CGRect menuFrame = _menuNavigationController.view.frame;
        CGRect frame = self.view.bounds;
        frame.size.height = frame.size.height - menuFrame.size.height;
        frame.origin.y = menuFrame.origin.y + menuFrame.size.height;
        _activityViewController.view.frame = frame;
        [self.view addSubview:_activityViewController.view];
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
    // Determine the origin of the frame. In iOS 8, we do not need to take into account the status
    // bar height, where on iOS 7 we do need to.
    [self.view layoutIfNeeded];
    CGRect menuFrame = _menuNavigationController.view.frame;
    if (![UIDevice iOS8]){
        menuFrame.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    else {
        menuFrame.origin.y = 0;
    }
    
    CGRect activityFrame = _activityViewController.view.frame;
    activityFrame.origin.y = menuFrame.origin.y + menuFrame.size.height;
    
    [UIView animateWithDuration:(animated ? 0.3 : 0)
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _menuNavigationController.view.frame = menuFrame;
                         _activityViewController.view.frame = activityFrame;
                         if ([UIDevice iOS8])
                             _transitionViewController.view.alpha = 0.2;
                     }
                     completion:^(BOOL finished) {
                         _showingMenu = true;
                     }];
}

-(void)hideMenuAnimated:(bool)animated
{
    [self.view layoutIfNeeded];
    CGRect menuFrame = _menuNavigationController.view.frame;
    menuFrame.origin.y = -menuFrame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height;
    
    CGRect activityFrame = _activityViewController.view.frame;
    activityFrame.origin.y = self.view.bounds.size.height;
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
    if (!toViewController)
        return;
    
    UIViewController *controller = _transitionViewController;
    [UIView animateWithDuration:duration
                          delay:0
                        options:options
                     animations:^{
                         [fromViewController.view removeFromSuperview];
                         [controller.view addSubview:toViewController.view];
                         if (animations) {
                             animations();
                         }
                     }
                     completion:^(BOOL finished) {
                         if (finished)
                         {
                             [fromViewController removeFromParentViewController];
                             [controller addChildViewController:toViewController];
                             if (completion) {
                                 completion(finished);
                             }
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

-(void)recentLineEventController:(JCRecentLineEventsTableViewController *)controller didSelectRecentLineEvent:(RecentLineEvent *)recentLineEvent
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(applicationSwitcher:shouldNavigateToRecentEvent:)]) {
        [self.delegate applicationSwitcher:self shouldNavigateToRecentEvent:recentLineEvent];
        [self hideMenuAnimated:YES];
    }
}

@end
