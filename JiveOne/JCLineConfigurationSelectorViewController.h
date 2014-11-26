//
//  JCLineSelectorViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"

@class JCLineConfigurationSelectorViewController;
@class LineConfiguration;

@protocol JCLineConfigurationSelectorViewControllerDelegate <NSObject>

- (void)lineConfigurationViewController:(JCLineConfigurationSelectorViewController *)controller didSelectLineConfiguration:(LineConfiguration *)selectedLineConfiguration;

@end

@interface JCLineConfigurationSelectorViewController : JCFetchedResultsTableViewController

@property (nonatomic, assign) id<JCLineConfigurationSelectorViewControllerDelegate> delegate;

@end
