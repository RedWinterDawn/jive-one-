//
//  JCDebugDIDTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCDebugDIDTableViewController.h"
#import "PBX.h"
#import "JCDebugBlockedContactsTableViewController.h"

@implementation JCDebugDIDTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.number.text = self.did.number;
    self.jrn.text = self.did.jrn;
    self.didId.text = self.did.didId;
    
    self.makeCall.text      = self.did.canMakeCall ? @"Yes" : @"No";
    self.receiveCall.text   = self.did.canReceiveCall ? @"Yes" : @"No";
    self.sendSMS.text       = self.did.canSendSMS ? @"Yes" : @"No";
    self.receiveSMS.text    = self.did.canReceiveSMS ? @"Yes" : @"No";
    
    self.pbx.text = self.did.pbx.name;
    self.blockedContacts.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.did.blockedContacts.count];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCDebugBlockedContactsTableViewController class]]) {
        ((JCDebugBlockedContactsTableViewController *)viewController).did = self.did;
    }
}

@end
