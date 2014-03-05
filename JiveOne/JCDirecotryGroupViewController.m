//
//  JCDirecotryGroupViewController.m
//  JiveOne
//
//  Created by Ethan Parker on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDirecotryGroupViewController.h"

@interface JCDirecotryGroupViewController ()

@end

@implementation JCDirecotryGroupViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    
    
//    // Here you'll see three test groups created. Each time you navigate to this view it'll load more so it'll get big until we fix it.
//    for (int i = 0; i < 3; i++) {
//        ContactGroup *group = [ContactGroup MR_createInContext:localContext];
//        group.groupName = [NSString stringWithFormat:@"GroupName = %d", i];
//        
//        if (i == 0) {
//            group.clientEntities = [NSArray arrayWithObjects:@"entities:eparker", @"entities:egueiros", nil];
//        }
//        else {
//            group.clientEntities = [NSArray arrayWithObjects:@"entities:eparker", nil];
//        }   
//        
//        [localContext MR_saveToPersistentStoreAndWait];
//    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.testArray = [[NSMutableArray alloc] initWithArray:[ContactGroup MR_findAllSortedBy:@"groupName" ascending:YES]];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // If you make lots of sections it repeats the array!.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        
        return 1;
        
    } else if (section == 1){
        
        return 1;
        
    } else {
        
        return self.testArray.count;
    }
    
    
    // Return the number of rows in the section.
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    //This whole "if" statement is to make "All Conacts" stand out as the most often tapped result in the table. It will take you back to the full company directory, where you can get to the detail view by tapping on the cell
    if (indexPath.section == 0) {
        cell.textLabel.text = @"All Contacts";
        cell.detailTextLabel.text = @"";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    // The purpose of making this blank cell is to make "All Contacts" stand out as a pseudo title
    } else if (indexPath.section == 1){
        
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
        
    } else {
        
        ContactGroup *group = self.testArray[indexPath.row];
        cell.textLabel.text = group.groupName;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = [(NSArray*)group.clientEntities componentsJoinedByString:@","];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSLog(@"Section: %ld , Row: %ld", (long)indexPath.section, (long)indexPath.row);
    //UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
//    if ([cell.textLabel.text isEqualToString:@"All Contacts"]) {
//        NSLog(@"You Clicked the title!!");
//    }
    
    
//    if (indexPath.row == 0) {
//        NSLog(@"you clicked the title");
//    }
}

// Nothing implemented yet, but we may need to use this method to pass information to the next view when we want to select contacts for groups?
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}

// This "+" button has a segue attached to it implemented in the storyboard. Click this to go to the "GroupSelector" VC
- (IBAction)addGroupButton:(id)sender {
    
    NSLog(@"addGroupButton was pressed, yo!");
}

@end
