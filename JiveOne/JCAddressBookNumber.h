//
//  JCAddressBookNumber.h
//  JiveOne
//
//  Created by Robert Barclay on 2/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAddressBookEntity.h"

@interface JCAddressBookNumber : JCAddressBookEntity

+ (NSArray *)addressBookNumbersForRecordRef:(ABRecordRef)recordRef;

@property (nonatomic, readonly) NSInteger identifer;

@end
