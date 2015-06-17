//
//  JCStaticTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@interface JCStaticTableViewController : UITableViewController

// Configurable Options
@property (nonatomic) BOOL hideSectionsWithHiddenRows;
@property (nonatomic) UITableViewRowAnimation insertTableViewRowAnimation;
@property (nonatomic) UITableViewRowAnimation deleteTableViewRowAnimation;
@property (nonatomic) UITableViewRowAnimation reloadTableViewRowAnimation;

// Change cell visible state
- (void)setCell:(UITableViewCell *)cell hidden:(BOOL)hidden;
- (void)setCells:(NSArray *)cells hidden:(BOOL)hidden;

// Cell State
- (BOOL)cellIsHidden:(UITableViewCell *)cell;
- (NSIndexPath *)indexPathForCell:(UITableViewCell *)cell;
- (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath;

- (void)reset;

- (void)startUpdates;
- (void)endUpdates;

- (void)addCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)path;
- (void)removeCell:(UITableViewCell *)cell;

- (CGFloat)heightForCell:(UITableViewCell *)cell;

@end