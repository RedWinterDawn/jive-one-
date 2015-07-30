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
#import "PhoneNumber.h"
#import "Extension.h"
#import "JCVoicemailNumber.h"
#import "User.h"

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

#pragma mark - Phone number search -

//  These methods search the combined phonebook of Jive contacts, local contacts and the local
//  address book contacts, and returns a phone number object that represents the phone number for
//  that requested name or name and number. This logic is used to identify a phone number and place
//  it into a object to provide its name, t9 value and formated and dialable value. If multiple
//  contacts were found, it returns a JCMultiPhoneNumber object that represents a phone number.

-(id<JCPhoneNumberDataSource>)phoneNumberForNumber:(NSString *)number name:(NSString *)name forPbx:(PBX *)pbx excludingLine:(Line *)line;
{
    
    
    // We must at least have a number. If we do not have a number, we return nil.
    if (!number) {
        return nil;
    }
    
    // Check if the number is voicemail
    if ([number isEqual:@"*99"]) {
        return [JCVoicemailNumber new];
    }
    
    // Check if the number is a jive contact.
    id<JCPhoneNumberDataSource> phoneNumber = [self extensionForNumber:number pbx:pbx excludingLine:line];
    if (phoneNumber) {
        return phoneNumber;
    }
    
    // Check if the number is a local contact from the local contacts address book.
    return [self localPhoneNumberForPhoneNumber:[JCPhoneNumber phoneNumberWithName:name number:number]context:pbx.managedObjectContext];
    
    // If we did not get a phone number object, we have a unknown number. If we have the name, we
    // can return a named number, otherwise we return an unknown number.
    if (name) {
        return [[JCPhoneNumber alloc] initWithName:name number:number];
    }
    return [JCUnknownNumber unknownNumberWithNumber:number];
}

/**
 * Check if the number is the extension for a jive contact. Since extensions are unique to a line,
 * and jive contacts represent a line rather than an person entity, line's name representing the
 * caller id is unique to the number, we only search on the basis of the number. if we have found
 * it, we do not need to search the rest of the phone book.
 */
-(id<JCPhoneNumberDataSource>)extensionForNumber:(NSString *)number pbx:(PBX *)pbx excludingLine:(Line *)line
{
    // We must at least have a number. If we do not have a number, we return nil.
    if (!number) {
        return nil;
    }
    
    if (line) {
        return [Extension extensionForNumber:number onPbx:pbx excludingLine:line];
    }
    
    return [Extension extensionForNumber:number onPbx:pbx];
}

-(id<JCPhoneNumberDataSource>)localPhoneNumberForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber context:(NSManagedObjectContext *)context
{
    // Get phone numbers from the address book for the given name and number. Since its possible to
    // have multiple contacts with the same number, we work with them as an array.
    NSMutableArray *phoneNumbers = [_addressBook fetchNumbersWithPhoneNumber:phoneNumber sortedByKey:NSStringFromSelector(@selector(number)) ascending:NO].mutableCopy;
    
    // If we have a local contact that matches one of our address contacts we swap the address book
    // contact for the local contact, and linke the addresbook record to local contact.
    //[self mapLocalContactsForPhoneNumbers:phoneNumbers number:number name:name context:context];
    
    NSUInteger count = phoneNumbers.count;
    if (count > 1) {
        return [JCMultiPersonPhoneNumber multiPersonPhoneNumberWithPhoneNumbers:phoneNumbers];
    } else if (count > 0) {
        return phoneNumbers.firstObject;
    }
    return phoneNumber;
}

//-(void)mapLocalContactsForPhoneNumbers:(NSMutableArray *)phoneNumbers number:(NSString *)number name:(NSString *)name context:(NSManagedObjectContext *)context
//{
//    if (!context) {
//        return;
//    }
//    
//    NSArray *localContacts = [self localContactsForName:name number:number context:context];
//    for (LocalContact *localContact in localContacts) {
//        if ([phoneNumbers containsObject:localContact]) {
//            NSInteger index = [phoneNumbers indexOfObject:localContact];
//            JCAddressBookNumber *number = [phoneNumbers objectAtIndex:index];
//            localContact.phoneNumber = number;
//            [phoneNumbers replaceObjectAtIndex:index withObject:localContact];
//        } else {
//            [phoneNumbers addObject:localContact];
//        }
//    }
//}

#pragma mark Private

-(NSArray *)localContactsForName:(NSString *)name number:(NSString *)number context:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [self predicateForName:name
                                            nameKey:NSStringFromSelector(@selector(name))
                                             number:number
                                          numberKey:NSStringFromSelector(@selector(number))];
    
    // Search the local contacts history stored in core data, to see if it tis a local contact which
    // we already know, and have a history with, so we can link it to that history.
    return [PhoneNumber MR_findAllWithPredicate:predicate inContext:context];
}

-(NSPredicate *)predicateForName:(NSString *)name nameKey:(NSString *)nameKey number:(NSString *)number numberKey:(NSString *)numberKey
{
    static NSString *predicateString = @"%K CONTAINS[cd] %@";
    static NSString *predicateNumberString = @"%K CONTAINS[cd] %@";
    
    if (!name) {
        return [NSPredicate predicateWithFormat:predicateNumberString, numberKey, number];
    }
    
    NSArray *predicates = @[[NSPredicate predicateWithFormat:predicateNumberString, numberKey, number],
                            [NSPredicate predicateWithFormat:predicateString, nameKey, name]];
    
    return [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
}

#pragma mark - Keyword Search -

-(void)phoneNumbersWithKeyword:(NSString *)keyword forUser:(User *)user forLine:(Line *)line sortedByKey:sortedByKey ascending:(BOOL)ascending completion:(void (^)(NSArray *phoneNumbers))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        Line *localLine = (Line *)[localContext objectWithID:line.objectID];
        User *localUser = (User *)[localContext objectWithID:user.objectID];
        NSArray *localPhoneNumbers = [self phoneNumbersWithKeyword:keyword
                                                           forUser:localUser
                                                           forLine:localLine
                                                       sortedByKey:NSStringFromSelector(@selector(name))
                                                         ascending:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *phoneNumbers = [NSMutableArray arrayWithCapacity:localPhoneNumbers.count];
            for (id<JCPhoneNumberDataSource> localPhoneNumber in localPhoneNumbers) {
                if ([localPhoneNumber isKindOfClass:[NSManagedObject class]]) {
                    NSManagedObject *localObject = (NSManagedObject *)localPhoneNumber;
                    NSManagedObject *object = [line.managedObjectContext objectWithID:localObject.objectID];
                    if ([object isKindOfClass:[PhoneNumber class]]) {
                        ((PhoneNumber *)object).phoneNumber = ((PhoneNumber *)localObject).phoneNumber;
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

-(NSArray *)phoneNumbersWithKeyword:(NSString *)keyword forUser:(User *)user forLine:(Line *)line sortedByKey:sortedByKey ascending:(BOOL)ascending
{
    NSMutableArray *numbers = [NSMutableArray array];
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    if (line && line.managedObjectContext != context) {
        context = line.managedObjectContext;
    }
    
    @autoreleasepool {
        NSArray *localPhoneNumbers = [_addressBook fetchNumbersWithKeyword:keyword sortedByKey:sortedByKey ascending:ascending].mutableCopy;
        [numbers addObjectsFromArray:localPhoneNumbers];
        
        if (user && line) {
            static NSString *extensionPredicateString = @"pbxId = %@ AND jrn != %@ AND (number CONTAINS %@ OR t9 BEGINSWITH %@)";
            NSPredicate *predicate = [NSPredicate predicateWithFormat:extensionPredicateString, line.pbx.pbxId, line.jrn, keyword, keyword];
            NSArray *extensions = [Extension MR_findAllWithPredicate:predicate inContext:user.managedObjectContext];
            [numbers addObjectsFromArray:extensions];
        }
        
        if (user) {
            static NSString *phoneNumberPredicateString = @"contact.user CONTAINS %@ AND (number CONTAINS %@ OR contact.name CONTAINS %@)";
            NSPredicate *predicate = [NSPredicate predicateWithFormat:phoneNumberPredicateString, user, keyword, keyword];
            NSArray *phoneNumbers = [PhoneNumber MR_findAllWithPredicate:predicate inContext:user.managedObjectContext];
            [numbers addObjectsFromArray:phoneNumbers];
        }
    }
    
    [numbers sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:sortedByKey ascending:ascending]]];
    return numbers;
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
