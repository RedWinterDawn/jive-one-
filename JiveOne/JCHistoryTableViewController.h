//
//  JCHistoryTableViewController.h
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentActivityTableViewController.h"

@interface JCHistoryTableViewController : JCRecentActivityTableViewController

@property (nonatomic, strong) NSFetchRequest *fetchRequest;

@end
