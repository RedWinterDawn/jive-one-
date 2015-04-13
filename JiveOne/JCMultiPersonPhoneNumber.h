//
//  JCMultiPersonPhoneNumber.h
//  JiveOne
//
//  Created by Robert Barclay on 4/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumber.h"

@interface JCMultiPersonPhoneNumber : JCPhoneNumber

@property (nonatomic, readonly) NSArray *phoneNumbers;

-(instancetype)initWithPhoneNumbers:(NSArray *)phoneNumbers;

@end
