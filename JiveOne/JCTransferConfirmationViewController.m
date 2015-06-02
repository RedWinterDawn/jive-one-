//
//  JCTransferConfirmationViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCTransferConfirmationViewController.h"

@implementation JCTransferConfirmationViewController


-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.currentCallersName.text        = self.transferLineSession.number.titleText;
    self.currentCallersNumber.text      = self.transferLineSession.number.detailText;
    self.transferToCallersName.text     = self.receivingLineSession.number.titleText;
    self.transferToCallersNumber.text   = self.receivingLineSession.number.detailText;
}

@end
