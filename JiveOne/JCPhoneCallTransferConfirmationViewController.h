//
//  JCTransferConfirmationViewController.h
//  JiveOne
//
//  Created by P Leonard on 10/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

#import "JCPhoneSipSession.h"

@interface JCPhoneCallTransferConfirmationViewController : UIViewController

@property (nonatomic, copy) JCPhoneSipSession *transferLineSession;
@property (nonatomic, copy) JCPhoneSipSession *receivingLineSession;

@property (weak, nonatomic) IBOutlet UILabel *currentCallersName;
@property (weak, nonatomic) IBOutlet UILabel *currentCallersNumber;
@property (weak, nonatomic) IBOutlet UILabel *transferToCallersName;
@property (weak, nonatomic) IBOutlet UILabel *transferToCallersNumber;

@end
