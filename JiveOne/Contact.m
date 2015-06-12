//
//  Contact.m
//  JiveOne
//
//  Created by Robert Barclay on 6/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Contact.h"
#import "PhoneNumber.h"
#import "JCPhoneNumberDataSourceUtils.h"

@implementation Contact

// Attributes

@dynamic etag;
@dynamic data;

// Relationships

@dynamic user;
@dynamic phoneNumbers;
@dynamic info;
@dynamic addresses;


// Overides
-(NSString *)number
{
    NSSet *phoneNumbers = self.phoneNumbers;
    if (phoneNumbers && phoneNumbers.count > 0) {
        PhoneNumber *phoneNumber = phoneNumbers.allObjects.firstObject;
        return phoneNumber.number;
    }
    return nil;
}

@end
