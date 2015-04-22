//
//  JCTransferConfirmationViewController.h
//  JiveOne
//
//  Created by P Leonard on 10/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

#import "JCLineSession.h"

@interface JCTransferConfirmationViewController : UIViewController

@property (nonatomic, copy) JCLineSession *transferLineSession;
@property (nonatomic, copy) JCLineSession *receivingLineSession;

@property (weak, nonatomic) IBOutlet UILabel *currentCallersName;
@property (weak, nonatomic) IBOutlet UILabel *currentCallersNumber;
@property (weak, nonatomic) IBOutlet UILabel *transferToCallersName;
@property (weak, nonatomic) IBOutlet UILabel *transferToCallersNumber;

@end
