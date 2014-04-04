//
//  JCDirectoryDetailViewController.h
//  JiveOne
//
//  Created by Doug Leonard on 2/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClientEntities.h"
#import "JCPersonCell.h"

@interface JCDirectoryDetailViewController : UITableViewController

@property (strong, nonatomic) ClientEntities *person;
@property (strong, nonatomic) NSDictionary *ABPerson;
@property (strong, nonatomic) JCPersonCell *personCell;

@end