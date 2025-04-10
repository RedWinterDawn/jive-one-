//
//  JCExternalContactListUnitTestDataFactory.m
//  JiveOne
//
//  Created by Robert Barclay on 4/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneBookTestDataFactory.h"
#import "JCAddressBookPerson.h"
#import "JCAddressBookNumber.h"
#import "JCAddressBook.h"

@interface JCAddressBook ()

- (instancetype)initWithPeople:(NSArray *)people numbers:(NSArray *)numbers;

@end

NSString *const kJCAddressBookTestDataFactoryDataFile = @"TestExternalContactListContents.plist";

@implementation JCPhoneBookTestDataFactory

+ (JCPhoneBook *)loadTestPhoneBook
{
    JCAddressBook *addressBook = [self loadTestAddressBook];
    return [[JCPhoneBook alloc] initWithAddressBook:addressBook];
}

+ (JCAddressBook *)loadTestAddressBook
{
    NSDictionary *addressBookData = [self loadTestAddessBookData];
    NSMutableArray *people  = [addressBookData objectForKey:kJCAddressBookPeople];
    NSMutableArray *numbers = [addressBookData objectForKey:kJCAddressBookNumbers];
    return [[JCAddressBook alloc] initWithPeople:people numbers:numbers];
}

+ (NSDictionary *)loadTestAddessBookData
{
    NSArray *pathParts = [@"TestExternalContactListContents.plist" componentsSeparatedByString:@"."];
    NSString *filePath = [[NSBundle bundleForClass:[self class]]
                          pathForResource:[pathParts objectAtIndex:0]
                          ofType:[pathParts objectAtIndex:1]];

    NSArray *contactList = [[NSArray alloc] initWithContentsOfFile:filePath];
    NSAssert(contactList != nil, @"Should not be null");
    NSAssert(contactList.count > 1, @"Should have at least on contact in the list");
    
    NSMutableSet *people  = [NSMutableSet new];
    NSMutableSet *numbers = [NSMutableSet new];
    for (NSDictionary *entry in contactList)
    {
        ABRecordRef record = [self recordForEntry:entry];
        JCAddressBookPerson *person = [JCAddressBookPerson addressBookPersonWithABRecordRef:record];
        [numbers addObjectsFromArray:person.phoneNumbers];
        [people addObject:person];
    }
    return @{kJCAddressBookPeople: people, kJCAddressBookNumbers: numbers};
}

#pragma mark - Private -

+ (ABRecordRef)recordForEntry:(NSDictionary *)entry
{
    ABRecordRef person = ABPersonCreate();
    NSString *first = [entry objectForKey:@"first"];
    NSString *last = [entry objectForKey:@"last"];
    ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)(first), NULL);
    ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFTypeRef)(last), NULL);

    ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    NSArray *phones = [entry objectForKey:@"phones"];
    for (NSDictionary *phone in phones) {
        NSString *type = [phone valueForKey:@"type"];
        NSString *number = [phone valueForKey:@"number"];
        ABMultiValueAddValueAndLabel(phoneNumberMultiValue, (__bridge CFTypeRef)(number), (__bridge CFStringRef)(type), NULL);
    }
    ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, nil);
    
    return person;
}

@end
