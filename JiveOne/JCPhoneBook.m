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
#import "Extension.h"

@interface JCPhoneBook () {
    JCAddressBook *_addressBook;
}

@end

@implementation JCPhoneBook

-(instancetype)init
{
    return [self initWithAddressBook:[JCAddressBook new]];
}

-(instancetype)initWithAddressBook:(JCAddressBook *)addressBook
{
    self = [super init];
    if (self) {
        _addressBook = addressBook;
    }
    return self;
}

#pragma mark - Public Methods -

-(id<JCPhoneNumberDataSource>)phoneNumberForNumber:(NSString *)number forPbx:(PBX *)pbx excludingLine:(Line *)line;
{
    return [self phoneNumberForName:nil number:number forPbx:pbx excludingLine:line];
}

-(id<JCPhoneNumberDataSource>)phoneNumberForName:(NSString *)name number:(NSString *)number forPbx:(PBX *)pbx excludingLine:(Line *)line;
{
    // We must at least have a number. If we do not have a number, we return nil.
    if (!number) {
        return nil;
    }
    
    // Check if the number is the extension for a jive contact. Since extensions are unique to a
    // line, and jive contacts represent a line rather than an person entity, line's name
    // representing the caller id is unique to the number, we only search on the basis of the number.
    // if we have found it, we do not need to search the rest of the phone book.
    Extension *extension = nil;
    if (line) {
        extension = [Extension extensionForNumber:number onPbx:pbx excludingLine:line];
    } else {
        extension = [Extension extensionForNumber:number onPbx:pbx];
    }
    if (extension) {
        return extension;
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
            localContact.phoneNumber = number;
            [phoneNumbers replaceObjectAtIndex:index withObject:localContact];
        } else {
            [phoneNumbers addObject:localContact];
        }
    }
    
    // if we have results determine if we need to return a multi phone number object or a single
    // phone number object.
    if (phoneNumbers.count > 0) {
        if (phoneNumbers.count > 1) {
            return [JCMultiPersonPhoneNumber multiPersonPhoneNumberWithPhoneNumbers:phoneNumbers];
        }
        else {
            return phoneNumbers.firstObject;
        }
    }
    
    // If we did not get a phone number object, we have a unknown number. If we have the name, we
    // can return a named number, otherwise we return an unknown number.
    if (name) {
        return [[JCPhoneNumber alloc] initWithName:name number:number];
    }
    return [JCUnknownNumber unknownNumberWithNumber:number];
}

-(void)phoneNumbersWithKeyword:(NSString *)keyword forLine:(Line *)line sortedByKey:sortedByKey ascending:(BOOL)ascending completion:(void (^)(NSArray *phoneNumbers))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        Line *localLine = (Line *)[localContext objectWithID:line.objectID];
        NSArray *localPhoneNumbers = [self phoneNumbersWithKeyword:keyword forLine:localLine sortedByKey:NSStringFromSelector(@selector(name)) ascending:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *phoneNumbers = [NSMutableArray arrayWithCapacity:localPhoneNumbers.count];
            for (id<JCPhoneNumberDataSource> localPhoneNumber in localPhoneNumbers) {
                if ([localPhoneNumber isKindOfClass:[NSManagedObject class]]) {
                    NSManagedObject *localObject = (NSManagedObject *)localPhoneNumber;
                    NSManagedObject *object = [line.managedObjectContext objectWithID:localObject.objectID];
                    if ([object isKindOfClass:[LocalContact class]]) {
                        ((LocalContact *)object).phoneNumber = ((LocalContact *)localObject).phoneNumber;
                    }
                    [phoneNumbers addObject:object];
                } else {
                    [phoneNumbers addObject:localPhoneNumber];
                }
            }
            
            if (completion) {
                completion(phoneNumbers);
            }
        });
    });
}

-(NSArray *)phoneNumbersWithKeyword:(NSString *)keyword forLine:(Line *)line sortedByKey:sortedByKey ascending:(BOOL)ascending
{
    NSMutableArray *phoneNumbers = [NSMutableArray array];
    
    @autoreleasepool {
        NSArray *localPhoneNumbers = [_addressBook fetchNumbersWithKeyword:keyword sortedByKey:sortedByKey ascending:ascending].mutableCopy;
        [phoneNumbers addObjectsFromArray:localPhoneNumbers];
        
        static NSString *predicateString = @"pbxId = %@ AND jrn != %@ AND (number CONTAINS %@ OR t9 BEGINSWITH %@)";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString, line.pbx.pbxId, line.jrn, keyword, keyword];
        NSArray *contacts = [Extension MR_findAllWithPredicate:predicate];
        [phoneNumbers addObjectsFromArray:contacts];
    }
    
    [phoneNumbers sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:sortedByKey ascending:ascending]]];
    return phoneNumbers;
}

#pragma mark - Private -

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
