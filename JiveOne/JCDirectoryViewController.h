//
//  JCDirectoryViewController.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCDirectoryViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
- (IBAction)refreshDirectory:(id)sender;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
