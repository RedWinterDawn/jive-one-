//
//  JCDirectoryDetailViewController.h
//  JiveOne
//
//  Created by Doug Leonard on 2/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PersonEntities.h"
#import "JCPersonCell.h"
#import "JCPeopleDetailCell.h"

@interface JCDirectoryDetailViewController : UITableViewController <JCPeopleDetailCellDelegate>

@property (strong, nonatomic) PersonEntities *person;
@property (strong, nonatomic) NSDictionary *ABPerson;
@property (strong, nonatomic) JCPersonCell *personCell;

@end