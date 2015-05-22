//
//  JCStoryboardLoaderViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCStoryboardLoaderViewController.h"

@interface JCStoryboardLoaderViewController ()
{
    UIViewController *_embeddedViewController;
}

@end

@implementation JCStoryboardLoaderViewController

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    UIViewController *scene = self.embeddedViewController;
    if (!scene) {
        return;
    }
    
    // Grabs the UINavigationItem stuff.
    UINavigationItem * navItem = self.navigationItem;
    UINavigationItem * linkedNavItem = scene.navigationItem;
    navItem.title = linkedNavItem.title;
    navItem.titleView = linkedNavItem.titleView;
    navItem.prompt = linkedNavItem.prompt;
    navItem.hidesBackButton = linkedNavItem.hidesBackButton;
    navItem.backBarButtonItem = linkedNavItem.backBarButtonItem;
    navItem.rightBarButtonItem = linkedNavItem.rightBarButtonItem;
    navItem.rightBarButtonItems = linkedNavItem.rightBarButtonItems;
    navItem.leftBarButtonItem = linkedNavItem.leftBarButtonItem;
    navItem.leftBarButtonItems = linkedNavItem.leftBarButtonItems;
    navItem.leftItemsSupplementBackButton = linkedNavItem.leftItemsSupplementBackButton;

    // Grabs the UITabBarItem
    // The link overrides the contained view's tab bar item.
    if (self.tabBarController)
        scene.tabBarItem = self.tabBarItem;
    
    // Grabs the edit button.
    UIBarButtonItem * editButton = self.editButtonItem;
    UIBarButtonItem * linkedEditButton = scene.editButtonItem;

    if (linkedEditButton) {
        editButton.enabled = linkedEditButton.enabled;
        editButton.image = linkedEditButton.image;
        editButton.landscapeImagePhone = linkedEditButton.landscapeImagePhone;
        editButton.imageInsets = linkedEditButton.imageInsets;
        editButton.landscapeImagePhoneInsets = linkedEditButton.landscapeImagePhoneInsets;
        editButton.title = linkedEditButton.title;
        editButton.tag = linkedEditButton.tag;
        editButton.target = linkedEditButton.target;
        editButton.action = linkedEditButton.action;
        editButton.style = linkedEditButton.style;
        editButton.possibleTitles = linkedEditButton.possibleTitles;
        editButton.width = linkedEditButton.width;
        editButton.customView = linkedEditButton.customView;
        editButton.tintColor = linkedEditButton.tintColor;
    }

    // Grabs the modal properties.
    self.modalTransitionStyle = scene.modalTransitionStyle;
    self.modalPresentationStyle = scene.modalPresentationStyle;
    self.definesPresentationContext = scene.definesPresentationContext;
    self.providesPresentationContextTransitionStyle = scene.providesPresentationContextTransitionStyle;
    
    // Grabs the popover properties.
    //self.preferredContentSize = scene.preferredContentSize;
    self.modalInPopover = scene.modalInPopover;
    
    // Grabs miscellaneous properties.
    self.title = scene.title;
    self.hidesBottomBarWhenPushed = scene.hidesBottomBarWhenPushed;
    self.editing = scene.editing;
    
    // Translucent bar properties.
    self.automaticallyAdjustsScrollViewInsets = scene.automaticallyAdjustsScrollViewInsets;
    self.edgesForExtendedLayout = scene.edgesForExtendedLayout;
    self.extendedLayoutIncludesOpaqueBars = scene.extendedLayoutIncludesOpaqueBars;
    self.modalPresentationCapturesStatusBarAppearance = scene.modalPresentationCapturesStatusBarAppearance;
    self.transitioningDelegate = scene.transitioningDelegate;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
}

-(void)viewWillLayoutSubviews
{
    UIViewController *scene = self.embeddedViewController;
    if (scene && scene.view.superview == nil) {
        scene.view.translatesAutoresizingMaskIntoConstraints = YES;
        scene.view.frame = self.view.bounds;
        [self addChildViewController:scene];
        [self.view addSubview:scene.view];
        [scene didMoveToParentViewController:self];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    
    // The linked scene defines the rotation.
    return [self.embeddedViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (BOOL)shouldAutorotate {
    
    // The linked scene defines autorotate.
    return [self.embeddedViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
    
    // The linked scene defines supported orientations.
    return [self.embeddedViewController supportedInterfaceOrientations];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.embeddedViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.embeddedViewController;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return [self.embeddedViewController preferredStatusBarUpdateAnimation];
}

- (BOOL)prefersStatusBarHidden {
    return [self.embeddedViewController prefersStatusBarHidden];
}


#pragma mark - Message forwarding

// The following methods are important to get unwind segues to work properly.

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    return [self.embeddedViewController canPerformUnwindSegueAction:action fromViewController:fromViewController withSender:sender];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return ([super methodSignatureForSelector:aSelector]
            ?:
            [self.embeddedViewController methodSignatureForSelector:aSelector]);
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([self.embeddedViewController respondsToSelector:[anInvocation selector]])
        [anInvocation invokeWithTarget:self.embeddedViewController];
    else
        [super forwardInvocation:anInvocation];
}

-(UIViewController *)embeddedViewController
{
    if (!_embeddedViewController) {
        NSString *storyboardIdentifier = self.storyboardIdentifier;
        if (!storyboardIdentifier) {
            return nil;
        }
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardIdentifier bundle:[NSBundle mainBundle]];
        if (!storyboard) {
            return nil;
        }
        
        NSString *viewControllerIdentifier = self.viewControllerIdentifier;
        if (viewControllerIdentifier) {
            _embeddedViewController = [storyboard instantiateViewControllerWithIdentifier:viewControllerIdentifier];
        } else {
            _embeddedViewController = [storyboard instantiateInitialViewController];
        }
    }
    return _embeddedViewController;
}


@end
