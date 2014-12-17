//
//  JCDebugUserTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 12/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"
#import "User.h"

@interface JCDebugUserTableViewController : UITableViewController

@property (nonatomic, strong) User *user;

@property (weak, nonatomic) IBOutlet UILabel *jiveUserId;
@property (weak, nonatomic) IBOutlet UILabel *pbxs;

@end
