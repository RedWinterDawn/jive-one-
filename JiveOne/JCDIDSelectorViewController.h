//
//  JCDIDSelectorViewController.h
//  JiveOne
//
//  Created by P Leonard on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"

@protocol JCDIDSelectorViewControllerDelegate;

@interface JCDIDSelectorViewController : JCFetchedResultsTableViewController

@property (nonatomic, weak) id <JCDIDSelectorViewControllerDelegate> delegate;

@end

@protocol JCDIDSelectorViewControllerDelegate <NSObject>

-(void)didUpdateDIDSelectorViewController:(JCDIDSelectorViewController *)viewController;

@end
