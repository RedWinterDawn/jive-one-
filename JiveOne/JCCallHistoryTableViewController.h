//
//  JCHistoryTableViewController.h
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentLineEventsTableViewController.h"

@interface JCCallHistoryTableViewController : JCRecentLineEventsTableViewController

@property (nonatomic, strong) NSFetchRequest *fetchRequest;

@end
