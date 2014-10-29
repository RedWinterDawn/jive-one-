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

@end
