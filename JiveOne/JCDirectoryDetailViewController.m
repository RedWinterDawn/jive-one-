//
//  JCDirectoryDetailViewController.m
//  JiveOne
//
//  Created by Doug Leonard on 2/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDirectoryDetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "JCMessageViewController.h"
#import "Company.h"


@interface JCDirectoryDetailViewController ()
#define NUMBER_OF_ROWS_IN_SECTION 3
#define NUMBER_OF_SECTIONS 1
#define ZERO 0
@end

@implementation JCDirectoryDetailViewController

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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    [self.tableView reloadData];
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
    return NUMBER_OF_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return NUMBER_OF_ROWS_IN_SECTION;
    }
    return ZERO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        if (indexPath.row == 0) {
            // Create first cell
            static NSString *CellIdentifier = @"DirectoryDetailNameCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            if(!self.ABPerson){
                cell.textLabel.text = self.person.firstLastName;
                [cell.imageView setImageWithURL:[NSURL URLWithString:self.person.picture]
                               placeholderImage:[UIImage imageNamed:@"avatar.png"]];
            } else {
                cell.textLabel.text = [self.ABPerson objectForKey:@"firstLast"];
                //TODO: picture
            }
            
            return cell;
        } else if (indexPath.row == 1) {
            // Create second cell
            static NSString *CellIdentifier = @"DirectoryDetailEmailCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            cell.textLabel.text = @"Email";
            if(!self.ABPerson){
                cell.detailTextLabel.text = self.person.email;
            } else {
                cell.detailTextLabel.text = @"";//[self.ABPerson objectForKey:@"email"];
            }
            
            return cell;
        } else {
            // Create all others
            static NSString *CellIdentifier = @"DirectoryDetailCompanyCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            cell.textLabel.text = @"Company";
            //convert "companies:jive" to "jive:
            if(!self.ABPerson){
                cell.detailTextLabel.text = self.person.entityCompany.name;
//                NSString *stringToDivide = self.person.entityCompany.name;
//                NSArray *stringParts = [stringToDivide componentsSeparatedByString:@":"];
//                if (stringParts[1]) {
//                    //Capitilize Company Name
//                    cell.detailTextLabel.text = [stringParts[1] capitalizedString];
//                }
            } else {
                cell.textLabel.text = @"Phone";
                cell.detailTextLabel.text = @"";//[self.ABPerson objectForKey:@"phone"];
            }
            return cell;
        }
    
}

// This button created in case we need to call methods in conjunction with starting a chat from directory detail view
- (IBAction)startChat:(id)sender {
    [self performSegueWithIdentifier:@"StartMessageSegue" sender:nil];
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"StartMessageSegue"]) {
        if (self.person) {
            [segue.destinationViewController setMessageType:JCNewConversationWithEntity];
            [segue.destinationViewController setPerson:self.person];
            
       //  an attempt to change the title of the chat to the person's name - but this just updates the nav bar button
       //  self.title = [[NSString alloc] initWithFormat:self.person.firstLastName];

            
        }
    }
    
    
}



@end
