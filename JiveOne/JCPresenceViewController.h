//
//  JCPresenceViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/4/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JCPresenceViewController;
@protocol JCPresenceDelegate <NSObject>

- (void)didChangePresence:(JCPresenceType)presenceType;

@end

@interface JCPresenceViewController : UITableViewController

@property (nonatomic, assign) id<JCPresenceDelegate> delegate;
@property (nonatomic, strong) UIImage *bluredBackgroundImage;

@end
