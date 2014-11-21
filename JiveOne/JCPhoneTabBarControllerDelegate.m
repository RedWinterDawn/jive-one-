//
//  JCPhoneTabBarControllerDelegate.m
//  JiveOne
//
//  Created by Robert Barclay on 11/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneTabBarControllerDelegate.h"
#import "JCBadgeManager.h"

NSString *const kJCPhoneTabBarControllerDialerRestorationIdentifier = @"DialerNavigationController";
NSString *const kJCPhoneTabBarControllerCallHistoryRestorationIdentifier = @"CallHistoryNavigationController";
NSString *const kJCPhoneTabBarControllerVoicemailRestorationIdentifier = @"VoicemailNavigationController";

@implementation JCPhoneTabBarControllerDelegate

-(instancetype)init
{
    self = [super init];
    if (self) {
        JCBadgeManager *badgeManager = [JCBadgeManager sharedManager];
        [badgeManager addObserver:self forKeyPath:@"missedCalls" options:NSKeyValueObservingOptionNew context:NULL];
        [badgeManager addObserver:self forKeyPath:NSStringFromSelector(@selector(voicemails)) options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"missedCalls"]) {
        [self setCountForViewController:[self findViewControllerForRestorationIdentifier:kJCPhoneTabBarControllerCallHistoryRestorationIdentifier]];
    }
    else if ([keyPath isEqualToString:NSStringFromSelector(@selector(voicemails))]) {
        [self setCountForViewController:[self findViewControllerForRestorationIdentifier:kJCPhoneTabBarControllerVoicemailRestorationIdentifier]];
    }
}

-(void)setTabBarController:(UITabBarController *)tabBarController
{
    _tabBarController = tabBarController;
    
    NSArray *viewControllers = tabBarController.viewControllers;
    for (UIViewController *viewController in viewControllers) {
        [self setCountForViewController:viewController];
    }
}

-(UIViewController *)findViewControllerForRestorationIdentifier:(NSString *)restorationIdentifier
{
    for (UIViewController *viewController in self.tabBarController.viewControllers) {
        if ([viewController.restorationIdentifier isEqualToString:restorationIdentifier]) {
            return viewController;
        }
    }
    return nil;
}

-(void)setCountForViewController:(UIViewController *)viewController
{
    if (!viewController)
        return;
    
    JCBadgeManager *badgeManager = [JCBadgeManager sharedManager];
    if ([viewController.restorationIdentifier isEqualToString:kJCPhoneTabBarControllerCallHistoryRestorationIdentifier]) {
        [self setTabBarItem:viewController.tabBarItem withCount:badgeManager.missedCalls];
    }
    else if ([viewController.restorationIdentifier isEqualToString:kJCPhoneTabBarControllerVoicemailRestorationIdentifier]) {
        [self setTabBarItem:viewController.tabBarItem withCount:badgeManager.voicemails];
    }
}

-(void)setTabBarItem:(UITabBarItem *)tabBarItem withCount:(NSUInteger)count
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (count > 0) {
            tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)count];
        }
        else {
            tabBarItem.badgeValue = nil;
        }
    });
}

@end
