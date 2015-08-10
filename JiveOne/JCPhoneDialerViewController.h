//
//  JCDialerViewController.h
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

#import "JCPhoneFormattedNumberLabel.h"
#import "JCPhoneNumberDataSource.h"
#import "JCPhoneManager.h"

@protocol JCPhoneDialerViewControllerDelegate;

@interface JCPhoneDialerViewController : UIViewController <JCFormattedPhoneNumberLabelDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (weak, nonatomic) IBOutlet JCPhoneFormattedNumberLabel *formattedPhoneNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *registrationStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *backspaceButton;
@property (weak, nonatomic) IBOutlet UILongPressGestureRecognizer *plusLongPressGestureRecognizer;
@property (weak, nonatomic) IBOutlet UILongPressGestureRecognizer *clearLongPressGestureRecognizer;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

// Optional Delegate
@property (nonatomic, weak) IBOutlet id <JCPhoneDialerViewControllerDelegate> delegate;

// Configurable Properties
@property (nonatomic) JCPhoneManagerDialType transferCallType;

// IBActions
- (IBAction)numPadPressed:(id)sender;
- (IBAction)numPadLogPress:(id)sender;
- (IBAction)initiateCall:(id)sender;
- (IBAction)backspace:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)cancel:(id)sender;

// Public Methods
+ (NSString *)characterFromNumPadTag:(NSInteger)tag;
- (id<JCPhoneNumberDataSource>)objectAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol JCPhoneDialerViewControllerDelegate <NSObject>

-(void)phoneDialerViewController:(JCPhoneDialerViewController *)controller shouldDialNumber:(id<JCPhoneNumberDataSource>)number;
-(void)shouldCancelPhoneDialerViewController:(JCPhoneDialerViewController *)controller;

@end
