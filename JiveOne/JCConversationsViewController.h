//
//  JCRecentViewController.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCConversationsViewController : UITableViewController

- (IBAction)refreshConversations:(id)sender;

- (void) loadDatasource;

@end
