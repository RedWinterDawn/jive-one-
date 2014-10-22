//
//  JCTransferConfirmationViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCTransferConfirmationViewController.h"
#import "JCCallCardManager.h"

@implementation JCTransferConfirmationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    JCCallCard *call = [self.transferInfo objectForKey:kJCCallCardManagerTransferedCall];
    JCCallCard *transferCall = [self.transferInfo objectForKey:kJCCallCardManagerNewCall];
    
    self.currentCallersName.text = call.callerId;
    self.currentCallersNumber.text = call.dialNumber;
    self.transferToCallersName.text = transferCall.callerId;
    self.transferToCallersNumber.text = transferCall.dialNumber;
}
@end
