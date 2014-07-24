//
//  JCConversationParticipantsTableViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 5/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationParticipantsTableViewController.h"
#import "JCPersonCell.h"

@interface JCConversationParticipantsTableViewController ()

@property (nonatomic, strong) NSMutableArray *peopleInConversation;

@end

@implementation JCConversationParticipantsTableViewController

static NSString *CellIdentifier = @"DirectoryCell";

- (void)setConversation:(Conversation *)conversation
{
    _conversation = conversation;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"JCPersonCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    

    [self loadPeopleInConversation];
    
}

- (void)loadPeopleInConversation
{
    if (!_peopleInConversation) {
        _peopleInConversation = [[NSMutableArray alloc] init];
    }
    else {
        [_peopleInConversation removeAllObjects];
    }
    
    NSInteger conversationCount = ((NSArray *)_conversation.entities).count;
    NSInteger personCount = [PersonEntities MR_findAll].count;
    
    if (conversationCount == personCount) {
        _peopleInConversation = [NSMutableArray arrayWithArray:[PersonEntities MR_findAll]];
    }
    else {    
        for (NSString *entityId in _conversation.entities) {
            PersonEntities *person = [PersonEntities MR_findFirstByAttribute:@"entityId" withValue:entityId];
            if (person) {
                [_peopleInConversation addObject:person];
            }
        }
    }
}
- (IBAction)showPeopleSearch:(id)sender {
    UINavigationController* peopleNavController = [self.storyboard instantiateViewControllerWithIdentifier:@"PeopleNavViewController"];
    JCDirectoryViewController *directory = peopleNavController.childViewControllers[0];
    directory.delegate = self;
    [self presentViewController:peopleNavController animated:YES completion:^{
        //Completed
    }];

}

- (void)dismissedWithPerson:(PersonEntities *)person
{
    [_peopleInConversation addObject:person];
    [self.tableView reloadData];
    
    if (_delegate && [_delegate respondsToSelector:@selector(didAddPersonFromParticipantView:)]) {
        [_delegate didAddPersonFromParticipantView:person];
    }
    
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return _peopleInConversation.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JCPersonCell *cell = [[JCPersonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    //cell.person = _peopleInConversation[indexPath.row];
    
    return cell;
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
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
