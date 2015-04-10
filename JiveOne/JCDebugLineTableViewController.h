//
//  JCLineTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCDebugLineTableViewController : UITableViewController

@property (nonatomic, strong) Line *line;

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *firstName;
@property (weak, nonatomic) IBOutlet UILabel *lastName;
@property (weak, nonatomic) IBOutlet UILabel *t9;
@property (weak, nonatomic) IBOutlet UILabel *extension;
@property (weak, nonatomic) IBOutlet UILabel *jrn;
@property (weak, nonatomic) IBOutlet UILabel *pbxId;
@property (weak, nonatomic) IBOutlet UILabel *lineId;

@property (weak, nonatomic) IBOutlet UILabel *mailboxUrl;
@property (weak, nonatomic) IBOutlet UILabel *mailbaxJrn;
@property (weak, nonatomic) IBOutlet UILabel *pbx;
@property (weak, nonatomic) IBOutlet UITableViewCell *lineConfiguration;

@end
