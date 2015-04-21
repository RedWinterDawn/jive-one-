//
//  JCStoryboardLoaderViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 4/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCStoryboardLoaderViewController : UIViewController

@property (nonatomic, strong) NSString *storyboardIdentifier;
@property (nonatomic, readonly) UIViewController *embeddedViewController;

@end
