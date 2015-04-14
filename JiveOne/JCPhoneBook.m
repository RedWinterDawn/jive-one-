//
//  JCPhoneBook.m
//  JiveOne
//
//  Created by Robert Barclay on 4/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneBook.h"
#import <objc/runtime.h>

#import "JCUnknownNumber.h"
#import "JCMultiPersonPhoneNumber.h"
#import "PBX.h"
#import "LocalContact.h"
#import "JiveContact.h"

@interface JCPhoneBook ()
{
    JCAddressBook *_addressBook;
}

@end

@implementation JCPhoneBook

-(instancetype)initWithAddressBook:(JCAddressBook *)addressBook
{
    self = [super init];
    if (self) {
        _addressBook = addressBook;
    }
    return self;
}

-(instancetype)init
{
    return [self initWithAddressBook:[JCAddressBook new]];
}

-(id<JCPhoneNumberDataSource>)phoneNumberForNumber:(NSString *)number forLine:(Line *)line;
{
    return [self phoneNumberForName:nil number:number forLine:line];
}

-(id<JCPhoneNumberDataSource>)phoneNumberForName:(NSString *)name number:(NSString *)number forLine:(Line *)line;
{
    // We must at least have a number.
    if (!number) {
        return nil;
    }
    
    // If we have a contacts, the number is the extension. Since extensions are unique to a line,
    // and contacts represent a line rather than an person entity, and the line has a name
    // representing the caller id, we only search on the basis of the extension.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbxId = %@ AND jrn != %@ AND extension = %@", line.pbx.pbxId, line.jrn, number];
    JiveContact *contact = [JiveContact MR_findFirstWithPredicate:predicate];
    if (contact) {
        return contact;
    }
    
    if (name) {
        predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR number CONTAINS[cd] = %@", name, number];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"number CONTAINS[cd] %@", number];
    }
    
    // Get phone numbers from the address book.
    NSMutableArray *phoneNumbers = [_addressBook fetchNumbersWithPredicate:predicate sortedByKey:@"name" ascending:YES].mutableCopy;
    
    // Search the local contacts history stored in core data, to see if it tis a local contact which
    // we already know, and have a history with, so we can link it to that history.
    NSArray *localHistory = [LocalContact MR_findAllWithPredicate:predicate];
    if (localHistory) {
        for (LocalContact *localContact in localHistory) {
            if ([phoneNumbers containsObject:localContact]) {
                NSInteger index = [phoneNumbers indexOfObject:localContact];
                JCAddressBookNumber *number = [phoneNumbers objectAtIndex:index];
                localContact.addressBookPerson = number.person;
                [phoneNumbers replaceObjectAtIndex:index withObject:localContact];
            }
        }
    }
    
    if (phoneNumbers.count > 0) {
        if (phoneNumbers.count > 1) {
            return [[JCMultiPersonPhoneNumber alloc] initWithPhoneNumbers:phoneNumbers];
        }
        else {
            return phoneNumbers.firstObject;
        }
    }
    
    return [JCUnknownNumber unknownNumberWithNumber:number];
}

-(NSArray *)phoneNumbersWithKeyword:(NSString *)keyword forLine:(Line *)line sortedByKey:sortedByKey ascending:(BOOL)ascending
{
    NSMutableArray *phoneNumbers = [NSMutableArray array];
    
    @autoreleasepool {
        NSArray *localPhoneNumbers = [_addressBook fetchNumbersWithKeyword:keyword sortedByKey:sortedByKey ascending:ascending].mutableCopy;
        [phoneNumbers addObjectsFromArray:localPhoneNumbers];
        
        static NSString *predicateString = @"pbxId = %@ AND jrn != %@ AND (extension CONTAINS %@ OR t9 BEGINSWITH %@)";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString, line.pbx.pbxId, line.jrn, keyword, keyword];
        NSArray *contacts = [JiveContact MR_findAllWithPredicate:predicate];
        [phoneNumbers addObjectsFromArray:contacts];
    }
    
    [phoneNumbers sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:sortedByKey ascending:ascending]]];
    return phoneNumbers;
}

@end

@implementation JCPhoneBook (Singleton)

+ (instancetype)sharedPhoneBook
{
    static JCPhoneBook *singleton = nil;
    static dispatch_once_t pred;        // Lock
    dispatch_once(&pred, ^{             // This code is called at most once per app
        singleton = [JCPhoneBook new];
    });
    return singleton;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end

@implementation UIViewController (JCPhoneBook)

- (void)setPhoneBook:(JCPhoneBook *)phoneBook {
    objc_setAssociatedObject(self, @selector(phoneBook), phoneBook, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(JCPhoneBook *)phoneBook
{
    JCPhoneBook *phoneBook = objc_getAssociatedObject(self, @selector(phoneBook));
    if (!phoneBook)
    {
        phoneBook = [JCPhoneBook sharedPhoneBook];
        objc_setAssociatedObject(self, @selector(phoneBook), phoneBook, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return phoneBook;
}

@end
