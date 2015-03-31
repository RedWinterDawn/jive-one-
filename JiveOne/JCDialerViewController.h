//
//  JCDialerViewController.h
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCDialStringLabel.h"

@interface JCDialerViewController : UIViewController <JCDialStringLabelDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *callBtn;
@property (weak, nonatomic) IBOutlet JCDialStringLabel *dialStringLabel;
@property (weak, nonatomic) IBOutlet UIButton *backspaceBtn;
@property (weak, nonatomic) IBOutlet UILabel *regestrationStatus;
@property (weak, nonatomic) IBOutlet UIButton *callButton;

-(IBAction)numPadPressed:(id)sender;
-(IBAction)initiateCall:(id)sender;
-(IBAction)backspace:(id)sender;

-(NSString *)characterFromNumPadTag:(int)tag;

@end
