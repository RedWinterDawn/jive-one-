//
//  JCHistoryTableViewController.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallHistoryTableViewController.h"
#import <JCPhoneModule/JCPhoneManager.h>
#import "MissedCall.h"

@implementation JCCallHistoryTableViewController

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self markMissedAsRead];
}
                 
-(void)markMissedAsRead {
    NSPredicate *predicate = self.fetchedResultsController.fetchRequest.predicate;
    NSPredicate *readPredicate = [NSPredicate predicateWithFormat:@"read == %@", @NO];
    predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, readPredicate]];
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *missedCalls = [MissedCall MR_findAllWithPredicate:predicate inContext:localContext];
        for (MissedCall *missedCall in missedCalls) {
            missedCall.read = YES;
        }
    }];
}

@end
