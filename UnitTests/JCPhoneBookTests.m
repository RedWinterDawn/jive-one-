//
//  JCPhoneBookTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"
#import "JCPhoneBook.h"
#import "JCAddressBookTestDataFactory.h"

@interface JCPhoneBookTests : JCBaseTestCase

@property (nonatomic, strong) JCPhoneBook *phoneBook;

@end

@interface JCAddressBook ()

- (instancetype)initWithPeople:(NSArray *)people numbers:(NSArray *)numbers;

@end

@implementation JCPhoneBookTests

- (void)setUp {
    [super setUp];
    
    NSDictionary *addressBookData = [JCAddressBookTestDataFactory loadTestAddessBookData];
    NSMutableArray *people  = [addressBookData objectForKey:kJCAddressBookPeople];
    NSMutableArray *numbers = [addressBookData objectForKey:kJCAddressBookNumbers];
    JCAddressBook *addressBook = [[JCAddressBook alloc] initWithPeople:people numbers:numbers];
    self.phoneBook = [[JCPhoneBook alloc] initWithAddressBook:addressBook];
}

- (void)tearDown {
    self.phoneBook = nil;
    [super tearDown];
}

@end
