//
//  JCGroupTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 6/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCGroupTableViewController.h"

#import "ContactGroup.h"

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
        self.parentViewController.navigationItem.leftBarButtonItem = nil;
    } else {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(cancel)];
        self.parentViewController.navigationItem.leftBarButtonItem = item;
    }
}

-(void)cancel
{
    [self.managedObjectContext reset];
    
    NSLog(@"Cancel");
    
    self.editing = FALSE;
}

-(void)save
{
    id<JCGroupDataSource> group = self.group;
    if (![group isKindOfClass:[ContactGroup class]]) {
        return;
    }
    
    ContactGroup *contactGroup = (ContactGroup *)group;
    NSManagedObjectContext *context = contactGroup.managedObjectContext;
    if (!context.hasChanges) {
        if (contactGroup.groupId) {
            return;
        }
        NSLog(@"Add Group");
    } else {
        NSLog(@"Update Group");
    }
}

@end
