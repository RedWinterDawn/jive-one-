//
//  JCDialerViewController.h
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCDialStringLabel.h"

@interface JCDialerViewController : UIViewController <JCDialStringLabelDelegate>

@property (nonatomic, weak) IBOutlet UIButton *callBtn;
@property (nonatomic, weak) IBOutlet JCDialStringLabel *dialStringLabel;
@property (nonatomic, weak) IBOutlet UIButton *backspaceBtn;

-(IBAction)numPadPressed:(id)sender;
-(IBAction)initiateCall:(id)sender;
-(IBAction)backspace:(id)sender;

@end
