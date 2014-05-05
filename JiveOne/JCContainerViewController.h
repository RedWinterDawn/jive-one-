//
//  JCContainerViewController.h
//  JiveOne
//
//  Created by Doug on 5/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCPage1ViewController.h"

@interface JCContainerViewController : UIViewController <UIPageViewControllerDataSource, Page1Delegate>


@property CGFloat percentDoneOfAnimationProgress;
@property (weak, nonatomic) id<Page1Delegate> delegate;
@end
