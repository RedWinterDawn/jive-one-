//
//  JCLineTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLineTableViewController.h"
#import "PBX.h"

@interface JCLineTableViewController ()

@end

@implementation JCLineTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.name.text = self.line.name;
    self.extension.text = self.line.extension;
    self.jrn.text = self.line.jrn;
    self.mailbaxJrn.text = self.line.mailboxJrn;
    self.mailboxUrl.text = self.line.mailboxUrl;
    self.pbx.text = self.line.pbx.name;
    
    if (self.line.lineConfiguration) {
        self.lineConfiguration.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        self.lineConfiguration.accessoryType = UITableViewCellAccessoryNone;
    }
    
    
}

@end
