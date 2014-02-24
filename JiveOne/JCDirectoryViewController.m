//
//  JCDirectoryViewController.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDirectoryViewController.h"
#import "ClientEntities.h"
#import "ClientMeta.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "JCOsgiClient.h"
#import "JCDirectoryDetailViewController.h"


@interface JCDirectoryViewController ()





@end

@implementation JCDirectoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    sections = [NSArray arrayWithObjects:@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil];
    self.clientEntitiesArray = [[NSMutableArray alloc] init]; //- this was an istance variable but now it's a property
    
    if ([self.segControl selectedSegmentIndex] == 0) {
        [self loadCompanyDirectory];
        [self refreshCompanyDirectory];
    } else {
        [self loadLocalDirectory];
    }
   
}



#pragma mark -ABPeoplePickerDelegate methods
- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    [self dismissViewControllerAnimated:NO completion:nil];
    return NO;
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

#pragma mark - Load Directories

- (void)loadLocalDirectory {
    
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                NSLog(@"User granted permission to contacts");
            } else {
                // User denied access
                // Display an alert telling user the contact could not be added
            }
        });
    }
  
    
    NSArray *allContacts = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    NSInteger sectionCount = [sections count];
    NSInteger allContactsCount = [allContacts count];
    for (int i = 0; i < sectionCount; i++) {
        NSMutableArray *section = [[NSMutableArray alloc] init];
        
        for (int j = 0; j < allContactsCount; j++) {
            NSString * firstName = (__bridge_transfer NSString *)(ABRecordCopyValue((__bridge ABRecordRef)(allContacts[j]), kABPersonFirstNameProperty));
            
            if ([firstName hasPrefix:sections[i]] || [firstName hasPrefix:[sections[i] lowercaseString]]) {
                NSString * lastName = (__bridge_transfer NSString *)(ABRecordCopyValue((__bridge ABRecordRef)(allContacts[j]), kABPersonLastNameProperty));
                NSString * email = (__bridge_transfer NSString *)(ABRecordCopyValue((__bridge ABRecordRef)(allContacts[j]), kABPersonEmailProperty));
                NSString * phone = (__bridge_transfer NSString *)(ABRecordCopyValue((__bridge ABRecordRef)(allContacts[j]), kABPersonPhoneProperty));
                
                NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
                [tempDictionary setObject:firstName forKey:@"firstName"];
                [tempDictionary setObject:[self padNilPhoneNames:lastName] forKey:@"lastName"];
                [tempDictionary setObject:[self padNilPhoneNames:[NSString stringWithFormat:@"%@ %@", firstName, lastName] ] forKey:@"firstLast"];
                [tempDictionary setObject:email forKey:@"email"];
                [tempDictionary setObject:phone forKey:@"phone"];
            
            [section addObject:tempDictionary];
                
            }
        }
        
        [self.clientEntitiesArray addObject:section];
    }
    
    [self.tableView reloadData];
}

-(NSString*) padNilPhoneNames:(NSString*)string{
    if(!string)
        return @"";
    else
        return string;
}

- (void)loadCompanyDirectory {
    
    for (NSString *section in sections) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(firstLastName BEGINSWITH[c] %@)", section];
        
        NSArray *sectionArray = [ClientEntities MR_findAllWithPredicate:pred];
        [self.clientEntitiesArray addObject:sectionArray];
    }
    [self.tableView reloadData];
}

- (IBAction)segmentChanged:sender {
    
    [self.clientEntitiesArray removeAllObjects];
    if ([self.segControl selectedSegmentIndex] == 0) {
        [self loadCompanyDirectory];
        NSLog(@"First segment!");
    } else {
        [self loadLocalDirectory];
        NSLog(@"Second Segment!");
    }
    
}


- (void)refreshCompanyDirectory
{
    [[JCOsgiClient sharedClient] RetrieveClientEntitites:^(id JSON) {
        
        NSString *me = [JSON objectForKey:@"me"];
        NSArray* entityArray = [JSON objectForKey:@"entries"];
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        
        [ClientEntities MR_truncateAllInContext:localContext];
        [ClientMeta MR_truncateAllInContext:localContext];
        [localContext MR_saveToPersistentStoreAndWait];
        
        for (NSDictionary* entity in entityArray) {
            ClientEntities *c_ent = [ClientEntities MR_createInContext:localContext];
            c_ent.lastModified = [entity objectForKey:@"lastModified"];
            c_ent.presence = [entity objectForKey:@"presence"];
            c_ent.company = [entity objectForKey:@"company"];
            c_ent.tags = [entity objectForKey:@"tags"];
            c_ent.location = [entity objectForKey:@"location"];
            c_ent.firstName = [[entity objectForKey:@"name"] objectForKey:@"first"];
            c_ent.lastName = [[entity objectForKey:@"name"] objectForKey:@"last"];
            c_ent.lastFirstName = [[entity objectForKey:@"name"] objectForKey:@"lastFirst"];
            c_ent.firstLastName = [[entity objectForKey:@"name"] objectForKey:@"firstLast"];
            c_ent.groups = [entity objectForKey:@"groups"];
            c_ent.urn = [entity objectForKey:@"urn"];
            c_ent.id = [entity objectForKey:@"id"];
            c_ent.entityId = [entity objectForKey:@"_id"];
            c_ent.me = [NSNumber numberWithBool:[c_ent.entityId isEqualToString:me]];
            c_ent.picture = [entity objectForKey:@"picture"];
            c_ent.email = [entity objectForKey:@"email"];
            
            ClientMeta *c_meta = [ClientMeta MR_createInContext:localContext];
            c_meta.entityId = entity[@"meta"][@"entity"];
            c_meta.lastModified = entity[@"meta"][@"lastModified"];
            c_meta.createDate = entity[@"meta"][@"createDate"];
            c_meta.pinnedActivityOrder = entity[@"meta"][@"pinnedActivityOrder"];
            c_meta.activityOrder = entity[@"meta"][@"activityOrder"];
            c_meta.urn = entity[@"meta"][@"urn"];
            c_meta.metaId = entity[@"meta"][@"id"];
            
            c_ent.entityMeta = c_meta;
            
            NSLog(@"id:%@ - _id:%@", [entity objectForKey:@"id"], [entity objectForKey:@"_id"]);
            
            [localContext MR_saveToPersistentStoreAndWait];
        }
        
        [self.clientEntitiesArray removeAllObjects];
        
        for (NSString *section in sections) {
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"(firstLastName BEGINSWITH[c] %@)", section];
            
            NSArray *sectionArray = [ClientEntities MR_findAllWithPredicate:pred];
            [self.self.clientEntitiesArray addObject:sectionArray];
            
        }
        
        [self.tableView reloadData];
        
    } failure:^(NSError *err) {
        NSLog(@"%@",[err description]);
    }];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (self.clientEntitiesArray.count == 0) {
        return 0;
    } else {
        return sections.count;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index
{
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [sections objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (self.clientEntitiesArray.count == 0) {
        return 0;
    } else {
        return [(NSArray*)self.clientEntitiesArray[section] count];
    }
    
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DirectoryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (self.clientEntitiesArray.count == 0) {
        return nil;
    } else {
        
        NSArray *section = self.clientEntitiesArray[indexPath.section];
        
        if([section[indexPath.row] isKindOfClass:[ClientEntities class]]){
        
            ClientEntities* person = section[indexPath.row];
            
            cell.textLabel.text = person.firstLastName;
            cell.detailTextLabel.text = person.email;
            [cell.imageView setImageWithURL:[NSURL URLWithString:person.picture]
                           placeholderImage:[UIImage imageNamed:@"avatar.png"]];
            
        }else{
            NSDictionary * pers = section[indexPath.row];
            cell.textLabel.text = [pers objectForKey:@"firstLast"];
            cell.detailTextLabel.text = @"";//[person objectForKey:@"email"];

            }
        
        
        return cell;
    }
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell *)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];

    if (self.segControl.selectedSegmentIndex == 0) {
        ClientEntities *person = self.clientEntitiesArray[indexPath.section][indexPath.row];
        [segue.destinationViewController setPerson:person];
        [segue.destinationViewController setABPerson:nil];
    }
    else
    {
        NSDictionary * person = self.clientEntitiesArray[indexPath.section][indexPath.row];
        // get ABDictionary
        [segue.destinationViewController setABPerson:person];
        [segue.destinationViewController setPerson:nil];
    }
}



- (IBAction)refreshDirectory:(id)sender {
    [self refreshCompanyDirectory];
}
@end







