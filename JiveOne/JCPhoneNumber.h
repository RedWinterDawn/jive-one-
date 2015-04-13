//
//  JCNumber.h
//  JiveOne
//
//  Created by Robert Barclay on 4/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberDataSource.h"

@interface JCPhoneNumber : NSObject <JCPhoneNumberDataSource>
{
    NSString *_name;
    NSString *_number;
}

-(instancetype)initWithName:(NSString *)name number:(NSNumber *)number;

@end