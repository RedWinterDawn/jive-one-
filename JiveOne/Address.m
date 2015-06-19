//
//  Address.m
//  JiveOne
//
//  Created by Robert Barclay on 6/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Address.h"
#import "Contact.h"
#import "NSManagedObject+Additions.h"

@implementation Address

-(void)willSave
{
    [super willSave];
    
    NSString *data = [NSString stringWithFormat:@"%@-%@-%@-%@", self.thoroughfare.lowercaseString, self.city.lowercaseString, self.region.lowercaseString, self.postalCode.lowercaseString];
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

@dynamic type;
@dynamic dataHash;
@dynamic city;
@dynamic country;
@dynamic latitude;
@dynamic longitude;
@dynamic postalCode;
@dynamic region;
@dynamic thoroughfare;
@dynamic contact;

@end
