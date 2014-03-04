//
//  JCRightToLeftSegue.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRightToLeftSegue.h"
#import <QuartzCore/QuartzCore.h>

@implementation JCRightToLeftSegue

- (void)perform
{
    __block UIViewController *sourceViewController = (UIViewController*)[self sourceViewController];
    __block UIViewController *destinationController = (UIViewController*)[self destinationViewController];
    
    CATransition* transition_out = [CATransition animation];
    transition_out.duration = 0.25f;
    transition_out.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition_out.type = kCATransitionPush; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition_out.subtype = kCATransitionFromLeft; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    
    
    CATransition* transition_in = [CATransition animation];
    transition_in.duration = 0.25f;
    transition_in.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition_in.type = kCATransitionPush; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition_in.subtype = kCATransitionFromRight; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    
    
    [sourceViewController.navigationController.view.layer addAnimation:transition_out
                                                                forKey:kCATransition];
    
//    [destinationController.navigationController.view.layer addAnimation:transition_in
//                                                                 forKey:kCATransition];
    
    [sourceViewController.navigationController pushViewController:destinationController animated:NO];

}

@end
