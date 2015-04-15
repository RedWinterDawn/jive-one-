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
    // We must at least have a number. If we do not have a number, we return nil.
    if (!number) {
        return nil;
    }
    
    // Check if the number is the extension for a jive contact. Since extensions are unique to a
    // line, and jive contacts represent a line rather than an person entity, line's name
    // representing the caller id is unique to the number, we only search on the basis of the number.
    // if we have found it, we do not need to search the rest of the phone book.
    JiveContact *jiveContact = [JiveContact jiveContactWithExtension:number forLine:line];
    if (jiveContact) {
        return jiveContact;
    }
    
    // Get phone numbers from the address book for the given name and number. Since its possible to
    // have multiple contacts with the same number, we work with them as an array.
    NSMutableArray *phoneNumbers = [self phoneNumbersForName:name number:number].mutableCopy;
    
    // If we have a local contact that matches one of our address contacts we swap the address book
    // contact for the local contact, and linke the addresbook record to local contact.
    NSArray *localContacts = [self localContactsForName:name number:number];
    for (LocalContact *localContact in localContacts) {
        if ([phoneNumbers containsObject:localContact]) {
            NSInteger index = [phoneNumbers indexOfObject:localContact];
            JCAddressBookNumber *number = [phoneNumbers objectAtIndex:index];
            localContact.addressBookPerson = number.person;
            [phoneNumbers replaceObjectAtIndex:index withObject:localContact];
        } else {
            [phoneNumbers addObject:localContact];
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

-(NSArray *)phoneNumbersForName:(NSString *)name number:(NSString *)number
{
    NSPredicate *predicate = [self predicateForName:name
                                            nameKey:NSStringFromSelector(@selector(name))
                                             number:number
                                          numberKey:NSStringFromSelector(@selector(dialableNumber))];
    
    return [_addressBook fetchNumbersWithPredicate:predicate sortedByKey:NSStringFromSelector(@selector(name)) ascending:YES];
}

-(NSArray *)localContactsForName:(NSString *)name number:(NSString *)number
{
    NSPredicate *predicate = [self predicateForName:name
                                            nameKey:NSStringFromSelector(@selector(name))
                                             number:number
                                          numberKey:NSStringFromSelector(@selector(number))];
    
    // Search the local contacts history stored in core data, to see if it tis a local contact which
    // we already know, and have a history with, so we can link it to that history.
    return [LocalContact MR_findAllWithPredicate:predicate];
}

-(NSPredicate *)predicateForName:(NSString *)name nameKey:(NSString *)nameKey number:(NSString *)number numberKey:(NSString *)numberKey
{
    static NSString *predicateString = @"%K CONTAINS[cd] %@";
    if (!name) {
        return [NSPredicate predicateWithFormat:predicateString, numberKey, number.numericStringValue];
    }
    
    NSArray *predicates = @[[NSPredicate predicateWithFormat:predicateString, numberKey, number.numericStringValue],
                            [NSPredicate predicateWithFormat:predicateString, nameKey, name]];
        
    return [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
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
