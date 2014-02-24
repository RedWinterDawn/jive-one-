//
//  JCDirectoryDetailViewController.m
//  JiveOne
//
//  Created by Doug Leonard on 2/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDirectoryDetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>



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
        if(indexPath.row==0){
            // Create first cell
            static NSString *CellIdentifier = @"DirectoryDetailNameCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            if(!self.ABPerson){
                cell.textLabel.text = self.person.firstLastName;
                [cell.imageView setImageWithURL:[NSURL URLWithString:self.person.picture]
                               placeholderImage:[UIImage imageNamed:@"avatar.png"]];
            }
            else{
                cell.textLabel.text = [self.ABPerson objectForKey:@"firstLast"];
                //TODO: picture
            }
            
            return cell;
        }
        
<<<<<<< HEAD
        else if(indexPath.row==1){
            // Create second cell
            static NSString *CellIdentifier = @"DirectoryDetailEmailCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            cell.textLabel.text = @"Email";
            if(!self.ABPerson){
                cell.detailTextLabel.text = self.person.email;
            }
            else{
                cell.detailTextLabel.text = @"";//[self.ABPerson objectForKey:@"email"];
            }
            
            return cell;
=======
        cell.textLabel.text = @"Company";
        //convert Company:"companies:jive" to "jive:
        NSString *stringToDivide = self.person.company;
        NSArray *stringParts = [stringToDivide componentsSeparatedByString:@":"];
        if (stringParts[1]) {
            //Capitilize Company Name
            cell.detailTextLabel.text = [stringParts[1] capitalizedString];
>>>>>>> Directory Detail ViewController 2-24-14
        }
        
        else {
            // Create all others
            static NSString *CellIdentifier = @"DirectoryDetailCompanyCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            cell.textLabel.text = @"Company";
            //convert "companies:jive" to "jive:
            if(!self.ABPerson){
                NSString *stringToDivide = self.person.company;
                NSArray *stringParts = [stringToDivide componentsSeparatedByString:@":"];
                if (stringParts[1]) {
                    //Capitilize Company Name
                    cell.detailTextLabel.text = [stringParts[1] capitalizedString];
                }
            }else{
                cell.textLabel.text = @"Phone";
                cell.detailTextLabel.text = @"";//[self.ABPerson objectForKey:@"phone"];
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

/*
 #pragma mark - Navigation
 
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 
 */

@end
