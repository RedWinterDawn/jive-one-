//
//  JCPhoneBookTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"
#import "JCPhoneBook.h"
#import "JCPhoneBookTestDataFactory.h"

@interface JCPhoneBookTests : JCBaseTestCase

@property (nonatomic, strong) JCPhoneBook *phoneBook;

@end

@implementation JCPhoneBookTests

- (void)setUp {
    [super setUp];
    self.phoneBook = [JCPhoneBookTestDataFactory loadTestPhoneBook];
}

- (void)tearDown {
    self.phoneBook = nil;
    [super tearDown];
}

@end
