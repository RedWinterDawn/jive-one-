//
//  ContactInfo.m
//  JiveOne
//
//  Created by Robert Barclay on 6/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "ContactInfo.h"
#import "Contact.h"
#import "NSManagedObject+Additions.h"

@implementation ContactInfo

-(void)willSave {
    [super willSave];
    
    NSString *data = [NSString stringWithFormat:@"%@-%@-%@", self.type.lowercaseString, self.key.lowercaseString, self.value.lowercaseString];
    [self setPrimitiveValue:data.MD5Hash forKey:NSStringFromSelector(@selector(dataHash))];
}

-(void)setOrder:(NSInteger)order
{
    [self setPrimitiveValueFromIntegerValue:order forKey:NSStringFromSelector(@selector(order))];
}

-(NSInteger)order
{
    return [self integerValueFromPrimitiveValueForKey:NSStringFromSelector(@selector(order))];
}

@dynamic dataHash;
@dynamic type;
@dynamic key;
@dynamic value;

@dynamic contact;

@end
