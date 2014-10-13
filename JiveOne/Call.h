//
//  Call.h
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "RecentEvent.h"

@interface Call : RecentEvent

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *number;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *extension;

@end
