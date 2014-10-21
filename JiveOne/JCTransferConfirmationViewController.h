//
//  JCTransferConfirmationViewController.h
//  JiveOne
//
//  Created by P Leonard on 10/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCDialStringLabel.h"

@interface JCTransferConfirmationViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *currentCallersName;
@property (weak, nonatomic) IBOutlet JCDialStringLabel *currentCallersNumber;
@property (weak, nonatomic) IBOutlet UILabel *transferToCallersName;
@property (weak, nonatomic) IBOutlet JCDialStringLabel *transferToCallersNumber;

@property (nonatomic, strong) NSDictionary *transferInfo;

@end
