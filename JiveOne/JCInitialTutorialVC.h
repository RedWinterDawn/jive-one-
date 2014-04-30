//
//  JCInitialTutorialVC.h
//  JiveOne
//
//  Created by Doug on 4/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCTutorialContentViewController.h"

@interface JCInitialTutorialVC : UIViewController <UIPageViewControllerDataSource>

- (IBAction)startButton:(id)sender;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSArray *pageTitles;

@end
