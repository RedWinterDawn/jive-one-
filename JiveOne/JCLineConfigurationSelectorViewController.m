//
//  JCLineSelectorViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLineConfigurationSelectorViewController.h"

#import "LineConfiguration.h"
#import "JCAuthenticationManager.h"

@implementation JCLineConfigurationSelectorViewController

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController)
    {
        NSFetchRequest *fetchRequest = [LineConfiguration MR_requestAllSortedBy:@"display" ascending:YES inContext:self.managedObjectContext];
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:self.managedObjectContext
                                                                               sectionNameKeyPath:nil
                                                                                        cacheName:nil];
    }
    return _fetchedResultsController;
}

- (void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[LineConfiguration class]])
    {
        LineConfiguration *lineConfiguration = (LineConfiguration *)object;
        cell.textLabel.text = lineConfiguration.display;
        
        if ([lineConfiguration isEqual:[JCAuthenticationManager sharedInstance].lineConfiguration]) {
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
    LineConfiguration *lineConfiguration = [self objectAtIndexPath:indexPath];
    
    // Mark line config as active, and all others inactive.
    NSArray *lineConfigurations = self.fetchedResultsController.fetchedObjects;
    for (LineConfiguration *lineConfig in lineConfigurations) {
        if (lineConfiguration == lineConfig){
            lineConfig.active = TRUE;
        }
        else{
            lineConfig.active = FALSE;
        }
    }
    
    // If we have changes, save them.
    if (lineConfiguration.managedObjectContext.hasChanges) {
        [JCAuthenticationManager sharedInstance].lineConfiguration = lineConfiguration;
        __autoreleasing NSError *error;
        if(![lineConfiguration.managedObjectContext save:&error])
            NSLog(@"%@", [error description]);
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(lineConfigurationViewController:didSelectLineConfiguration:)]) {
        [self.delegate lineConfigurationViewController:self didSelectLineConfiguration:lineConfiguration];
    }
}

@end
