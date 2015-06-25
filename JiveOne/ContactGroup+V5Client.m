//
//  ContactGroup+V5Client.m
//  JiveOne
//
//  Created by Robert Barclay on 6/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "ContactGroup+V5Client.h"

#import "Contact.h"
#import "ContactGroup.h"
#import "ContactGroupAssociation.h"

#import "JCV5ApiClient.h"

NSString *const kContactGroupIdKey     = @"id";
NSString *const kContactNameKey        = @"name";

@implementation ContactGroup (V5Client)

-(NSDictionary *)serializedData
{
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:self.groupId forKey:kContactGroupIdKey];
    [data setValue:self.name forKey:kContactNameKey];
    return data;
}




@end
