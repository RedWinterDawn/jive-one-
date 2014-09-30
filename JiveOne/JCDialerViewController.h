//
//  JCDialerViewController.h
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCDialerViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIButton *muteBtn;
@property (nonatomic, weak) IBOutlet UIButton *speakerBtn;
@property (nonatomic, weak) IBOutlet UIButton *callBtn;

@property (nonatomic, weak) IBOutlet UITextField *dialString;

-(IBAction)numPadPressed:(id)sender;
-(IBAction)speakerToggle:(id)sender;
-(IBAction)muteToggle:(id)sender;
-(IBAction)initiateCall:(id)sender;

@end
