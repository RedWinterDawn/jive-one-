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
    
    self.currentCallersName.text              = self.transferLineSession.callTitle;
    self.currentCallersNumber.dialString      = self.transferLineSession.callDetail;
    self.transferToCallersName.text           = self.receivingLineSession.callTitle;
    self.transferToCallersNumber.dialString   = self.receivingLineSession.callDetail;
}

@end
