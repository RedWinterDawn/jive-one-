//
//  JCGroupTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 6/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCGroupTableViewController.h"

@implementation JCGroupTableViewController

-(void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (!editing) {
        [self save];
    }
    
    [super setEditing:editing animated:animated];
    [self layoutForEditing:editing animated:YES];
}

-(void)layoutForEditing:(BOOL)editing animated:(BOOL)animated
{
    if (!editing) {
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(cancel)];
        self.navigationItem.leftBarButtonItem = item;
    }
}

-(void)cancel
{
    NSLog(@"Cancel");
}

-(void)save
{
    NSLog(@"Save");
}

@end
