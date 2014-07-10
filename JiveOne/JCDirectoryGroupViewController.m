//
//  JCDirecotryGroupViewController.m
//  JiveOne
//
//  Created by Ethan Parker on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDirectoryGroupViewController.h"
#import "JCGroupSelectorViewController.h"
#import "Lines+Custom.h"
#import "PBX+Custom.h"

@interface JCDirectoryGroupViewController ()
{
    NSManagedObjectContext *localContext;
}

@end

@implementation JCDirectoryGroupViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // This creates the main context used in this class via MagicalRecord, an open-source framework for interacting with CoreData
    localContext = [NSManagedObjectContext MR_contextForCurrentThread];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.groupArray = [[NSMutableArray alloc] initWithArray:[ContactGroup MR_findAllSortedBy:@"groupName" ascending:YES]];
	self.pbxArray = [[NSMutableArray alloc] initWithArray:[PBX MR_findAllSortedBy:@"name" ascending:YES]];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // If you make lots of sections it repeats the array!.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        
        return 1;
        
    } else if (section == 1){
        
        return self.pbxArray.count;
        
    } else {
        
        return self.groupArray.count;
    }
    
    // Return the number of rows in the section.
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 1:
			return @"Organization";
			break;
		
		case 2:
			return @"Groups";
			break;
		default:
			return @"";
			break;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    //This whole "if" statement is to make "All Conacts" stand out as the most often tapped result in the table. It will take you back to the full company directory, where you can get to the detail view by tapping on the cell
    if (indexPath.section == 0) {
        cell.textLabel.text = @"All Contacts";
        cell.detailTextLabel.text = @"";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    // The purpose of making this blank cell is to make "All Contacts" stand out as a pseudo title
    } else if (indexPath.section == 1){
        
		PBX *pbx = self.pbxArray[indexPath.row];
        cell.textLabel.text = pbx.name;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    } else {
        
		
        ContactGroup *group = self.groupArray[indexPath.row];
        cell.textLabel.text = group.groupName;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        //cell.detailTextLabel.text = [(NSArray*)group.clientEntities componentsJoinedByString:@","];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSLog(@"Section: %ld , Row: %ld", (long)indexPath.section, (long)indexPath.row);
    //UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
	else if (indexPath.section == 1) {
		PBX *pbx = self.pbxArray[indexPath.row];
		[self performSegueWithIdentifier:@"groupContactSegue" sender:pbx];
	}
	else if (indexPath.section == 2) {
        ContactGroup *group = self.groupArray[indexPath.row];
        [self performSegueWithIdentifier:@"groupContactSegue" sender:group];
    }
    
}

// This allows cells to be editable, we made it so the first cell which navigates back to "All Contacts" isn't deleteable
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 || indexPath.section == 1) {
        return NO;
    }
    
    return YES;
}

// This allows you to delete a group, first it is deleted from the datamodel, from CoreData and the array stored in memory
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the row from the data source - using MagicalRecord to edit CoreData - all the contact groupe are shown in the third section of the table, hence "indexPath.section == 2"
        if (indexPath.section == 2) {
            
            ContactGroup *group = self.groupArray[indexPath.row];
            [self.groupArray removeObjectAtIndex:indexPath.row];
            [group MR_deleteInContext:localContext];
            [localContext MR_saveToPersistentStoreAndWait];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
       
    }
}

// We pass information from the current ViewControllerl to the selector view
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    JCGroupSelectorViewController *groupSelectorVC = (JCGroupSelectorViewController *)[[segue destinationViewController] visibleViewController];
    if ([sender isKindOfClass:[ContactGroup class]]) {
        
        [groupSelectorVC setGroupEdit:sender];
    }
	else if ([sender isKindOfClass:[PBX class]]) {
		[groupSelectorVC setPbxEdit:sender];
	}
    
}

// This "+" button has a segue attached to it implemented in the storyboard. Click this to go to the "GroupSelector" VC
- (IBAction)addGroupButton:(id)sender {
    
}

@end
