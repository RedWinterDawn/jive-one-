//
//  JCHistoryTableViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallHistoryTableViewController.h"

// Managers
#import "JCPhoneManager.h"

// Managed objects
#import "Call.h"
#import "MissedCall.h"
#import "RecentLineEvent.h"

@implementation JCCallHistoryTableViewController

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *missedCalls = [MissedCall MR_findByAttribute:@"read" withValue:@NO inContext:localContext];
        for (MissedCall *missedCall in missedCalls) {
            missedCall.read = YES;
        }
    }];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - Delegate Handlers

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Call *call = (Call *)[self objectAtIndexPath:indexPath];
    [self dialPhoneNumber:call
           usingLine:self.authenticationManager.line
              sender:tableView];
}

@end
