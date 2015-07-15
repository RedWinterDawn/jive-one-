//
//  Group.m
//  JiveOne
//
//  Created by Robert Barclay on 6/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Group.h"

@implementation Group

// Attributes

@dynamic name;
@dynamic groupId;

// Protocol Attributes

-(NSSet *)members
{
    return nil; // To be implemented by Subclasses of the managed this abstract manage object.
}

-(NSString *)sectionName
{
    return nil;
}

@end
