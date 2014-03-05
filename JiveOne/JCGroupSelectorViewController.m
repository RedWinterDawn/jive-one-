//
//  JCGroupSelectorViewController.m
//  JiveOne
//
//  Created by Ethan Parker on 3/4/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCGroupSelectorViewController.h"
#import "JCPersonCell.h"
#import "ContactGroup.h"

@interface JCGroupSelectorViewController ()

// Created an insitance variable "itemChecked" as an array to store the index path of each cell checked.
{
    NSMutableArray *itemChecked;
}

@end

@implementation JCGroupSelectorViewController

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
    
    // new means alloc init
    itemChecked = [NSMutableArray new];
    
    self.sections = [NSArray arrayWithObjects:@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil];
    self.companyContactsArray = [[NSMutableArray alloc] init];
    [self loadCompanyDirectory];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadCompanyDirectory {
    
    for (NSString *section in self.sections) {
        
        // retrieve entities where first name starts with letter of alphabet
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(firstLastName BEGINSWITH[c] %@)", section];
        NSArray *sectionArray = [ClientEntities MR_findAllWithPredicate:pred];
        
        // sort array with bases on firstLastName property
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"firstLastName" ascending:YES];
        NSArray *sortedArray = [sectionArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
        
        [self.companyContactsArray addObject:sortedArray];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return self.sections.count;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.sections;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index
{
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.sections objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return [(NSArray*)self.companyContactsArray[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    JCPersonCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier ];
    
    
    if (self.companyContactsArray.count == 0) {
        cell.textLabel.text = @"No contacts";
        return cell;
    } else {
        cell = [[JCPersonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    //Company contacts
    
    NSArray *section = self.companyContactsArray[indexPath.section];
    
    if (section.count != 0) {
//        NSLog(@"Section: %ld Row: %ld", indexPath.section, (long)indexPath.row);
        ClientEntities *person = section[indexPath.row];
        cell.textLabel.text = person.firstLastName;
        cell.detailTextLabel.text = person.email;
        
        // Created an insitance variable "itemChecked" as an array to store the index path of each cell checked.
        if ([itemChecked containsObject:indexPath]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    // Created an insitance variable "itemChecked" as an array to store the index path of each cell checked.
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [itemChecked addObject:indexPath];
    } else if ((cell.accessoryType = UITableViewCellAccessoryCheckmark)) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [itemChecked removeObject:indexPath];
    }
    
}

// Done button action at top right of group creator modal
- (IBAction)saveGroupDoneButton:(id)sender {
    
    [self addTitleToGroup];
}

- (void)addTitleToGroup {
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Please name new group"
                                                      message:nil
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"OK", nil];
    
    [message setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [message show];
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        NSLog(@"cancel was clicked");
    } else {
        UITextField *textfield =  [alertView textFieldAtIndex: 0];
        NSLog(@"%@", textfield.text);
        
        if ([textfield.text isEqualToString:@""]) {
            return;
        }
        
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        ContactGroup *group = [ContactGroup MR_createInContext:localContext];
        group.groupName = textfield.text;
        
        NSMutableArray *selectedEntities = [[NSMutableArray alloc] init];
        
        for (NSIndexPath *indexPath in itemChecked) {
             NSString *entityId = ((ClientEntities *)self.companyContactsArray[indexPath.section][indexPath.row]).entityId;
            [selectedEntities addObject:entityId];
        }
        
        group.clientEntities = selectedEntities;
        
        [localContext MR_saveToPersistentStoreAndWait];
    }
    
     [self dismissViewControllerAnimated:YES completion:nil];
}

// Cancel button action at top left of group creator modal
- (IBAction)cancelGrouSelectorModal:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}




- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}



@end
