//
//  JCAddressBookEntity.h
//  JiveOne
//
//  Created by Robert Barclay on 4/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import AddressBook;

#import <JCPhoneModule/JCPhoneNumber.h>
#import "JCPersonDataSource.h"

@interface JCAddressBookEntity : JCPhoneNumber <JCPersonDataSource>

// Identifers
@property (nonatomic, readonly) NSInteger recordId;
@property (nonatomic, readonly) NSString *personHash;

- (instancetype)initWithNumber:(NSString *)number record:(ABRecordRef)record;

@end
