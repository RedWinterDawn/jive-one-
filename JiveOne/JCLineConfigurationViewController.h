//
//  JCLineConfigurationViewController.h
//  JiveOne
//
//  Created by P Leonard on 12/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPickerViewController.h"

@class JCLineConfigurationViewController;

@protocol JCLineConfigurationViewControllerDelegate <NSObject>

-(void)lineConfigurationViewControllerShouldDismiss:(JCLineConfigurationViewController *)controller;

@end

@interface JCLineConfigurationViewController : JCPickerViewController

@property (weak, nonatomic) IBOutlet id <JCLineConfigurationViewControllerDelegate> delegate;

@end
