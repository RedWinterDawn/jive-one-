//
//  JCAppDelegate.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@interface JCAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, weak) NSMutableDictionary* registrationOptions;
@property (nonatomic, weak) NSString* gcmSenderID;
@property BOOL connectedToGCM;

@end
