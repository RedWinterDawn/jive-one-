//
//  JCContactDetailTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 4/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "StaticDataTableViewController.h"
#import "JCPersonManagedObject.h"

@interface JCContactDetailTableViewController : StaticDataTableViewController

@property (strong, nonatomic) JCPersonManagedObject *person;

@property (weak, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *extensionCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *jiveIdCell;

@end
