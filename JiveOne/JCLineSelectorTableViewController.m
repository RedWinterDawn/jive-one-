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
        User *user = [JCAuthenticationManager sharedInstance].user;
        if (user)
        {
            NSManagedObjectContext *context = self.managedObjectContext;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx.user = %@", user];
            NSFetchRequest *fetchRequest = [Line MR_requestAllSortedBy:@"extension" ascending:YES withPredicate:predicate inContext:context];
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
        cell.textLabel.text = [NSString stringWithFormat:@"%@ on %@", line.extension, line.pbx.name];
        if ([line isEqual:[JCAuthenticationManager sharedInstance].line]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

#pragma mark Caller View Controller Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Line *line = [self objectAtIndexPath:indexPath];
    
    // Mark line config as active, and all others inactive.
    NSArray *lines = self.fetchedResultsController.fetchedObjects;
    for (Line *item in lines) {
        if (line == item){
            item.active = TRUE;
        }
        else{
            item.active = FALSE;
        }
    }
    
    // If we have changes, save them.
    if (line.managedObjectContext.hasChanges) {
        [JCAuthenticationManager sharedInstance].line = line;
        __autoreleasing NSError *error;
        if(![line.managedObjectContext save:&error])
            NSLog(@"%@", [error description]);
    }
}

@end
