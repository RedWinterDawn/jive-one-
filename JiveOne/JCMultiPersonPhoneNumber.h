//
//  JCMultiPersonPhoneNumber.h
//  JiveOne
//
//  A subclass of JCPhoneNumber that allows for multiple phone numbers to represented by a single
//  object conforming to the JCPhoneNumberDataSource protocol. This class figures out the combined
//  names of the phone contacts for display.
//
//  It has a requirement that the dialable string of the phone number for each of the phone number
//  objects be identical. Thier formatted forms may vary from different contact sources, but thier
//  dialable 10 digit string must be the same otherwise it will throw an exception.
//
//  Created by Robert Barclay on 4/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumber.h"

@interface JCMultiPersonPhoneNumber : JCPhoneNumber

@property (nonatomic, readonly) NSArray *phoneNumbers;

+(instancetype)multiPersonPhoneNumberWithPhoneNumbers:(NSArray *)phoneNumbers;

@end
