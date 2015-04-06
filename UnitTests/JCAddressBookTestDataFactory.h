//
//  JCExternalContactListUnitTestDataFactory.h
//  JiveOne
//
//  Created by Robert Barclay on 4/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import AddressBook;
@import Foundation;

@interface JCAddressBookTestDataFactory : NSObject

+ (NSDictionary *) loadTestAddessBookData;

+ (ABRecordRef)recordForEntry:(NSDictionary *)entry;

@end
