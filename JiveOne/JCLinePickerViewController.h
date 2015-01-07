//
//  JCPbxConfigurationViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//
#import "JCVisualEffectsView.h"
#import "JCPickerViewController.h"


@interface JCLinePickerViewController : JCPickerViewController
@property (weak, nonatomic) IBOutlet JCVisualEffectsView *logingBackgroundView;
@property (weak, nonatomic) IBOutlet JCVisualEffectsView *pickerViewBackground;


@end
