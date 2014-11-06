//
//  JCPhoneTabBarControllerDelegate.h
//  JiveOne
//
//  Created by Robert Barclay on 11/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kJCPhoneTabBarControllerDialerRestorationIdentifier;
extern NSString *const kJCPhoneTabBarControllerCallHistoryRestorationIdentifier;
extern NSString *const kJCPhoneTabBarControllerVoicemailRestorationIdentifier;

@interface JCPhoneTabBarControllerDelegate : NSObject <UITabBarControllerDelegate>

@property (nonatomic, weak) IBOutlet UITabBarController *tabBarController;

@end
