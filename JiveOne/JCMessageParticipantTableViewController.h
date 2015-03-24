//
//  JCMessageParticipantViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@class JCMessageParticipantTableViewController;

@protocol JCMessageParticipantTableViewControllerDelegate <NSObject>

-(void)messageParticipantTableViewController:(JCMessageParticipantTableViewController *)controller didSelectParticipants:(NSArray *)participants;

@end

@interface JCMessageParticipantTableViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet id<JCMessageParticipantTableViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;

@end
