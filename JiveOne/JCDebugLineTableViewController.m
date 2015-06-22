//
//  JCLineTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDebugLineTableViewController.h"
#import "PBX.h"
#import "Line.h"

@interface JCDebugLineTableViewController ()

@end

@implementation JCDebugLineTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Line *line = self.line;
    self.name.text       = line.name;
    self.t9.text         = line.t9;
    self.extension.text  = line.number;
    self.jrn.text        = line.jrn;
    self.pbxId.text      = line.pbxId;
    self.lineId.text     = line.lineId;
    self.mailbaxJrn.text = line.mailboxJrn;
    self.mailboxUrl.text = line.mailboxUrl;
    self.pbx.text        = line.pbx.name;
    
    if (self.line.lineConfiguration) {
        self.lineConfiguration.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        self.lineConfiguration.accessoryType = UITableViewCellAccessoryNone;
    }
    
    
}

@end
