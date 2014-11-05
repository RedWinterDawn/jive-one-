//
//  JCRecentEventCell.h
//  JiveOne
//
//  Created by Robert Barclay on 10/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCTableViewCell.h"
#import "RecentEvent.h"

@interface JCRecentEventCell : JCTableViewCell

@property (nonatomic, strong) RecentEvent *recentEvent;

@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) IBOutlet UILabel *number;
@property (nonatomic, weak) IBOutlet UILabel *extension;
@property (nonatomic, weak) IBOutlet UILabel *date;

@property (nonatomic, getter=isRead) BOOL read;

@end
