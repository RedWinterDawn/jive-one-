//
//  JCDIDSelectorViewController.m
//  JiveOne
//
//  Created by P Leonard on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCDIDSelectorViewController.h"

#import "JCAuthenticationManager.h"
#import "DID.h"
#import "User.h"
#import "PBX.h"

#import "NSString+Additions.h"

@implementation JCDIDSelectorViewController

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController)
    {
        PBX *pbx = [JCAuthenticationManager sharedInstance].pbx;
        if (pbx)
        {
            NSManagedObjectContext *context = self.managedObjectContext;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx = %@ AND receiveSMS = %@", pbx, @YES];
            NSFetchRequest *fetchRequest = [DID MR_requestAllSortedBy:@"number" ascending:YES withPredicate:predicate inContext:context];
            super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                 managedObjectContext:context
                                                                                   sectionNameKeyPath:nil
                                                                                            cacheName:nil];
        }
    }
    return _fetchedResultsController;
}

- (void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[DID class]])
    {
        DID *did = (DID *)object;
        if (did.sendSMS || did.receiveSMS) {
            
        cell.textLabel.text = did.formattedNumber;
        if ([did isEqual:[JCAuthenticationManager sharedInstance].did]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }
}


#pragma mark Caller View Controller Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DID *did = (DID *)[self objectAtIndexPath:indexPath];
    [JCAuthenticationManager sharedInstance].did = did;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        DID *currentDID = (DID *)[localContext objectWithID:did.objectID];
        NSArray *numbers = [DID MR_findAllWithPredicate:self.fetchedResultsController.fetchRequest.predicate inContext:localContext];
        for (DID *item in numbers) {
            if (currentDID == item){
                item.userDefault = TRUE;
            }
            else{
                item.userDefault = FALSE;
            }
        }
    }];
}

@end
