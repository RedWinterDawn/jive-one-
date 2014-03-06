//
//  JCGroupSelectorViewController.h
//  JiveOne
//
//  Created by Ethan Parker on 3/4/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClientEntities.h"
#import "ContactGroup.h"

@interface JCGroupSelectorViewController : UITableViewController <UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray *companyContactsArray;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *contactGroupArray;
@property (nonatomic, strong) ContactGroup *groupEdit;

@end
