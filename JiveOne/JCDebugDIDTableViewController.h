//
//  JCDebugDIDTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"
#import "DID.h"

@interface JCDebugDIDTableViewController : UITableViewController

@property (nonatomic, strong) DID *did;

@property (weak, nonatomic) IBOutlet UILabel *number;
@property (weak, nonatomic) IBOutlet UILabel *didId;
@property (weak, nonatomic) IBOutlet UILabel *jrn;
@property (weak, nonatomic) IBOutlet UILabel *makeCall;
@property (weak, nonatomic) IBOutlet UILabel *receiveCall;
@property (weak, nonatomic) IBOutlet UILabel *sendSMS;
@property (weak, nonatomic) IBOutlet UILabel *receiveSMS;
@property (weak, nonatomic) IBOutlet UILabel *pbx;
@property (weak, nonatomic) IBOutlet UILabel *blockedContacts;

@end
