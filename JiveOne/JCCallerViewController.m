//
//  JCCallerViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallerViewController.h"



@implementation JCCallerViewController



-(IBAction)warmTransfer:(id)sender{
    UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"warmTransferModal"];
    [self addChildViewController:viewController];
    
    CGRect bounds = self.view.bounds;
    CGRect frame = self.view.frame;
    frame.origin.y = frame.origin.y + frame.size.height;
    viewController.view.frame = frame;
    
    [self.view addSubview:viewController.view];
    [UIView animateWithDuration:0.6
                     animations:^{
                         viewController.view.frame = bounds;
                     }
                     completion:^(BOOL finished) {
        
                     }];
    
    
}

-(IBAction)blindTransfer:(id)sender{
    
}

-(IBAction)speaker:(id)sender{
    
}

-(IBAction)keypad:(id)sender{
    
}

-(IBAction)addCall:(id)sender{
    
}

-(IBAction)mute:(id)sender{
    
}



@end
