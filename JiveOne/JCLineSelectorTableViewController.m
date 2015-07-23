//
//  JCLineSelectorViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLineSelectorTableViewController.h"

#import "User.h"
#import "Line.h"
#import "PBX.h"
#import "JCAuthenticationManager.h"

@implementation JCLineSelectorTableViewController

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController)
    {
        User *user = self.authenticationManager.user;
        if (user)
        {
            NSManagedObjectContext *context = self.managedObjectContext;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx.user = %@", user];
            NSFetchRequest *fetchRequest = [Line MR_requestAllSortedBy:@"number" ascending:YES withPredicate:predicate inContext:context];
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
    if ([object isKindOfClass:[Line class]])
    {
        Line *line = (Line *)object;
        cell.textLabel.text = [NSString stringWithFormat:@"%@ on %@", line.number, line.pbx.name];
        if ([line isEqual:self.authenticationManager.line]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.accessoryView.tintColor = [UIColor grayColor];
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

#pragma mark Caller View Controller Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Line *line = (Line *)[self objectAtIndexPath:indexPath];
    self.authenticationManager.line = line;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Line *localLine = (Line *)[localContext objectWithID:line.objectID];
        NSArray *lines = [Line MR_findAllWithPredicate:self.fetchedResultsController.fetchRequest.predicate inContext:localContext];
        for (Line *item in lines) {
            if (localLine == item){
                item.active = TRUE;
            }
            else{
                item.active = FALSE;
            }
        }
    }];
}

@end
