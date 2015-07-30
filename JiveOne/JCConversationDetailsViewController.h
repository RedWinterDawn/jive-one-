//
//  JCConversationDetailsViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 5/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "StaticDataTableViewController.h"
#import "JCMessageGroup.h"

@interface JCConversationDetailsViewController : StaticDataTableViewController

@property (nonatomic, weak) IBOutlet UITableViewCell *phoneNumberCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *blockNumberCell;
@property (nonatomic, weak) IBOutlet UISwitch *blockSwitch;

@property (nonatomic, strong) JCMessageGroup *conversationGroup;

-(IBAction)toggleBlock:(id)sender;

@end
