//
//  JCContainerViewController.h
//  JiveOne
//
//  Created by Doug on 5/5/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCContainerViewController : UIViewController <UIPageViewControllerDataSource>
- (IBAction)dismissButtonPressed:(id)sender;
@property (nonatomic, strong) UIImage *bluredBackgroundImage;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

@end
