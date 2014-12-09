//
//  JCPbxConfigurationViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPickerViewController.h"

@class JCPbxConfigurationViewController;

@protocol JCPbxConfigurationViewControllerDelegate <NSObject>

-(void)pbxConfigurationViewControllerShouldDismiss:(JCPbxConfigurationViewController *)controller;

@end

@interface JCPbxConfigurationViewController : JCPickerViewController

@property (weak, nonatomic) IBOutlet id <JCPbxConfigurationViewControllerDelegate> delegate;

@end
