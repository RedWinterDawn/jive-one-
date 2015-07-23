//
//  ContactGroup.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "InternalExtensionGroup.h"

#import "InternalExtension.h"
#import "PBX.h"


@implementation InternalExtensionGroup

@dynamic groupId;
@dynamic name;

@dynamic internalExtensions;

-(NSSet *)members
{
    return self.internalExtensions;
}

-(NSString *)sectionName
{
    InternalExtension *internalExtension = self.internalExtensions.allObjects.firstObject;
    return internalExtension.pbx.name;
}

@end
