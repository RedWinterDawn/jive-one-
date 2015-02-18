//
//  JCAddressBookPerson.h
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JCPersonDataSource.h"

@import AddressBook;

@interface JCAddressBookPerson : NSObject <JCPersonDataSource>

-(instancetype)initWithABRecordRef:(ABRecordRef)recordRef;

// Identifers
@property (nonatomic, readonly) NSInteger recordId;
@property (nonatomic, readonly) NSString *personId;
@property (nonatomic, readonly) NSString *personHash;

@end
