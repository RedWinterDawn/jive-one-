//
//  JCDialerViewController.h
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCFormattedPhoneNumberLabel.h"

@interface JCDialerViewController : UIViewController <JCFormattedPhoneNumberLabelDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet JCFormattedPhoneNumberLabel *formattedPhoneNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *registrationStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *backspaceButton;
@property (weak, nonatomic) IBOutlet UILongPressGestureRecognizer *plusLongPressGestureRecognizer;
@property (weak, nonatomic) IBOutlet UILongPressGestureRecognizer *clearLongPressGestureRecognizer;

-(IBAction)numPadPressed:(id)sender;
-(IBAction)numPadLogPress:(id)sender;

-(IBAction)initiateCall:(id)sender;

-(IBAction)backspace:(id)sender;
-(IBAction)clear:(id)sender;

-(NSString *)characterFromNumPadTag:(NSInteger)tag;

@end
