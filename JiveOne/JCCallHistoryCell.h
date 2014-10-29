//
//  JCHistoryCell.h
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentEventCell.h"
#import "Call.h"

@interface JCCallHistoryCell : JCRecentEventCell

@property (nonatomic, strong) Call *call;

@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) IBOutlet UILabel *number;
@property (nonatomic, weak) IBOutlet UILabel *extension;
@property (nonatomic, weak) IBOutlet UIImageView *icon;
@property (nonatomic, weak) IBOutlet UILabel *timestamp;

@end
