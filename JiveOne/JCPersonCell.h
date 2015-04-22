//
//  JCPersonCell.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPresenceCell.h"
#import "JCPersonDataSource.h"

@interface JCPersonCell : JCPresenceCell

@property (nonatomic) id<JCPersonDataSource> person;

@end

