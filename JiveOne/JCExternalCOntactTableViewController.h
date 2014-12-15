//
//  UITableViewController+JCExternalCOntactTableViewController.h
//  JiveOne
//
//  Created by P Leonard on 12/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

@interface JCExternalContactTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel *firstName;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumber;


@end
