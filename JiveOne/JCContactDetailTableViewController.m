//
//  JCContactDetailTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCContactDetailTableViewController.h"

#import "JCPhoneManager.h"
#import "JCAuthenticationManager.h"

#import "Extension.h"
#import "Contact.h"
#import "Line.h"
#import "PBX.h"
#import "User.h"

@implementation JCContactDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self cell:self.nameCell setHidden:YES];
    [self cell:self.extensionCell setHidden:YES];
    [self cell:self.jiveIdCell setHidden:YES];
    
    JCPersonManagedObject *person = self.person;
    if (person) {
        
        if (person.name) {
            self.title = person.titleText;
            self.nameCell.detailTextLabel.text  = person.name;
            [self cell:self.nameCell setHidden:FALSE];
        }
        
        if ([person isKindOfClass:[Extension class]]) {
            self.extensionCell.detailTextLabel.text = person.number;
            [self cell:self.extensionCell setHidden:NO];
            
            if ([person isKindOfClass:[Contact class]]) {
                NSString *jiveId = ((Contact *)person).jiveUserId;
                if (jiveId) {
                    self.jiveIdCell.detailTextLabel.text = jiveId;
                    [self cell:self.jiveIdCell setHidden:NO];
                }
            }
            else {
                self.jiveIdCell.detailTextLabel.text = ((Line *)person).pbx.user.jiveUserId;
                [self cell:self.jiveIdCell setHidden:NO];
            }
        }
    }
    [self reloadDataAnimated:NO];
}

-(IBAction)callExtension:(id)sender
{
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITableViewCell *cell = (UITableViewCell *)((UITapGestureRecognizer *)sender).view;
        if (cell == self.extensionCell) {
            [self dialPhoneNumber:self.person
                        usingLine:self.authenticationManager.line
                           sender:sender];
        }
    }
}

@end
