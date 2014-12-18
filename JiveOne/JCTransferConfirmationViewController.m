//
//  JCTransferConfirmationViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCTransferConfirmationViewController.h"
#import "JCPhoneManager.h"

@implementation JCTransferConfirmationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    JCCallCard *call = [self.transferInfo objectForKey:kJCPhoneManagerTransferedCall];
    JCCallCard *transferCall = [self.transferInfo objectForKey:kJCPhoneManagerNewCall];
    
    self.currentCallersName.text = call.callerId;
    self.currentCallersNumber.text = call.dialNumber;
    self.transferToCallersName.text = transferCall.callerId;
    self.transferToCallersNumber.text = transferCall.dialNumber;
}
@end
