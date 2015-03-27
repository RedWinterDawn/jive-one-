//
//  JCAddressBook.m
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAddressBook.h"
#import "JCAddressBookNumber.h"

@implementation JCAddressBook

+(void)personForPersonId:(NSString *)personId personHash:(NSString *)hash completion:(void (^)(JCAddressBookPerson *person, NSError *error))completion
{
    [self personForRecordId:personId.intValue personHash:hash completion:completion];
}

+(void)personForRecordId:(ABRecordID)recordId personHash:(NSString *)hash completion:(void (^)(JCAddressBookPerson *person, NSError *error))completion
{
    [JCAddressBook getPermission:^(BOOL success, ABAddressBookRef addressBook, NSError *error) {
        if (success) {
            ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook,recordId);
            if (completion) {
                completion([[JCAddressBookPerson alloc] initWithABRecordRef:person], nil);
            }
        }
        else {
            if (completion) {
                completion(nil, error);
            }
        }
    }];
}

+(void)fetchAllPeople:(void (^)(NSArray *contacts, NSError *error))completion {
    [self fetchAllPeopleWithSortDescriptors:nil completion:completion];
}

+(void)fetchAllPeopleWithSortDescriptors:(NSArray *)sortDescriptors
                              completion:(void (^)(NSArray *contacts, NSError *error))completion
{
    [self fetchWithPredicate:nil sortDescriptors:nil completion:completion];
}

+(void)fetchNumbersWithKeyword:(NSString *)keyword
                    completion:(void (^)(NSArray *numbers, NSError *error))completion
{
    [self fetchWithKeyword:keyword completion:^(NSArray *people, NSError *error) {
        NSMutableArray *numbers = [NSMutableArray array];
        for (JCAddressBookPerson *person in people) {
            NSArray *phones = person.phoneNumbers;
            if (phones) {
                for (JCAddressBookNumber *phoneNumber in phones) {
                    [numbers addObject:phoneNumber];
                }
            }
        }
        if (completion) {
            completion(numbers, error);
        }
    }];
}

+(void)fetchWithKeyword:(NSString *)keyword
             completion:(void (^)(NSArray *people, NSError *error))completion {
    [self fetchWithKeyword:keyword sortDescriptors:nil completion:completion];
}

+(void)fetchWithKeyword:(NSString *)keyword
        sortDescriptors:(NSArray *)sortDescriptors
             completion:(void (^)(NSArray *contacts, NSError *error))completion
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock: ^(id record, NSDictionary *bindings) {
        BOOL result = NO;
        
        NSString *string = keyword.lowercaseString;
        
        ABRecordRef person = (__bridge ABRecordRef)record;
        NSString *firstName = ((__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty)).lowercaseString;
        if ([firstName containsString:string]) {
            result = YES;
        }
        
        NSString *middleName = ((__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonMiddleNameProperty)).lowercaseString;
        if ([middleName containsString:string]) {
            result = YES;
        }
        
        NSString *lastName = ((__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty)).lowercaseString;
        if ([lastName containsString:string]) {
            result = YES;
        }
        
        NSString *nickname = ((__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonNicknameProperty)).lowercaseString;
        if ([nickname containsString:string]) {
            result = YES;
        }
        
        NSString *organizationName = ((__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty)).lowercaseString;
        if ([organizationName containsString:string]) {
            result = YES;
        }
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue( person, kABPersonPhoneProperty);
        for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++) {
            NSString *phoneNumber = ((__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, i)).numericStringValue;
            if ([phoneNumber containsString:string]) {
                result = YES;
                break;
            }
        }
        
        CFRelease(phoneNumbers);
        return result;
    }];

    [self fetchWithPredicate:predicate sortDescriptors:sortDescriptors completion:completion];
}

+(void)fetchWithPredicate:(NSPredicate *)predicate
          sortDescriptors:(NSArray *)sortDescriptors
               completion:(void (^)(NSArray *contacts, NSError *error))completion
{
    [self getPermission:^(BOOL success, ABAddressBookRef addressBook, NSError *error) {
        if (!success) {
            completion(nil, error);
        } else {
            [self readAddressBook:addressBook
                        predicate:predicate
                  sortDescriptors:sortDescriptors
                       completion:completion];
        }
    }];
}

+(void)fetchPeopleWithNumbers:(NSSet *)numbers
                   completion:(void (^)(NSArray *, NSError *))completion
{
    NSMutableArray *predicates = [NSMutableArray new];
    for (NSString *number in numbers) {
        __block NSString *blockNumber = number;
        NSPredicate *predicate = [NSPredicate predicateWithBlock: ^(id record, NSDictionary *bindings) {
            BOOL result = NO;
            NSString *string = blockNumber.numericStringValue;
            ABRecordRef person = (__bridge ABRecordRef)record;
            ABMultiValueRef phoneNumbers = ABRecordCopyValue( person, kABPersonPhoneProperty);
            for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++) {
                NSString *phoneNumber = ((__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, i)).numericStringValue;
                if ([phoneNumber containsString:string] || [string containsString:phoneNumber]) {
                    result = YES;
                    break;
                }
            }
            
            CFRelease(phoneNumbers);
            return result;
        }];
        
        [predicates addObject:predicate];
    }
    
    NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
    [self fetchWithPredicate:predicate sortDescriptors:nil completion:completion];
}

+(void)fetchPeopleWithNumber:(NSString *)number
                  completion:(void (^)(NSArray *people, NSError *error))completion
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock: ^(id record, NSDictionary *bindings) {
        BOOL result = NO;
        NSString *string = number.numericStringValue;
        ABRecordRef person = (__bridge ABRecordRef)record;
        ABMultiValueRef phoneNumbers = ABRecordCopyValue( person, kABPersonPhoneProperty);
        for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++) {
            NSString *phoneNumber = ((__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, i)).numericStringValue;
            if ([phoneNumber containsString:string] || [string containsString:phoneNumber]) {
                result = YES;
                break;
            }
        }
        
        CFRelease(phoneNumbers);
        return result;
    }];
    
    [self fetchWithPredicate:predicate sortDescriptors:nil completion:completion];
}

NSString *const kNameFormattingTwoPeople = @"%@, %@";
NSString *const kNameFormattingThreePlusPeople = @"%@,...+%li";

+(NSString *)nameForPeople:(NSArray *)people {
    NSString *name;
    if (people && people.count > 0) {
        id<JCPersonDataSource> person = people.firstObject;
        if (people.count > 1) {
            if (people.count == 2) {
                id<JCPersonDataSource> otherPerson = people.lastObject;
                name = [NSString stringWithFormat:kNameFormattingTwoPeople, person.firstName, otherPerson.firstName];
            } else {
                name = [NSString stringWithFormat:kNameFormattingThreePlusPeople, person.firstName, (long)people.count-1];
            }
        } else {
            name = person.name;
        }
    }
    return name;
}


#pragma mark - Private -

+(void)getPermission:(void (^)(BOOL success, ABAddressBookRef addressBook, NSError *error))completion
{
    CFErrorRef err;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &err);
    if (err) {
        completion(NO, NULL, nil);
        //CFRelease(err);
        return;
    }
    
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (![NSThread isMainThread]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(granted, addressBook, (__bridge NSError *)error);
                    CFRelease(addressBook);
                });
            } else {
                completion(granted, addressBook, (__bridge NSError *)error);
                CFRelease(addressBook);
            }
        });
    } else if(status == kABAuthorizationStatusAuthorized) {
        completion(YES, addressBook, nil);
        CFRelease(addressBook);
    } else {
        NSError *error = [NSError errorWithDomain:@"AddressBookErrorDomain" code:0 userInfo:nil];
        completion(NO, nil, error);
        CFRelease(addressBook);
    }
}

+ (void)readAddressBook:(ABAddressBookRef)addressBook
              predicate:(NSPredicate *)predicate
        sortDescriptors:(NSArray *)sortDescriptors
             completion:(void (^)(NSArray *contacts, NSError *error))completion
{
    if (completion) {
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSArray *people;
        if (predicate) {
            people = [self addressBookPeopleForRecordArray:[((__bridge NSArray *)allPeople) filteredArrayUsingPredicate:predicate]
                                           sortDescriptors:sortDescriptors];
        }
        else {
            people = [self addressBookPeopleForRecordArray:(__bridge NSArray *)allPeople
                                           sortDescriptors:sortDescriptors];
        }
        
        completion(people, nil);
        CFRelease(allPeople);
    }
}

+ (NSArray *)addressBookPeopleForRecordArray:(NSArray *)arrayOfPeople
                             sortDescriptors:(NSArray *)sortDesciptors
{
    NSMutableArray *addressBook = [NSMutableArray arrayWithCapacity:arrayOfPeople.count];
    for(NSUInteger index = 0; index < arrayOfPeople.count; index++){
        ABRecordRef currentPerson = (__bridge ABRecordRef)[arrayOfPeople objectAtIndex:index];
        [addressBook addObject:[[JCAddressBookPerson alloc] initWithABRecordRef:currentPerson]];
    }
    [addressBook sortUsingDescriptors:sortDesciptors];
    return addressBook;
}

@end

@implementation JCAddressBook (FormattedNames)

+(void)formattedNamesForNumbers:(NSSet *)numbers
                          begin:(void (^)())begin
                number:(void (^)(NSString *name, NSString *number))number
                     completion:(void (^)(BOOL success, NSError *error))completion
{
    [self fetchPeopleWithNumbers:numbers completion:^(NSArray *people, NSError *error) {
        
        if (begin) {
            begin();
        }
        if (!error && number) {
            for (NSString *numberString in numbers) {
                NSMutableArray *peopleGroup = [NSMutableArray new];
                for (JCAddressBookPerson *person in people) {
                    if ([person hasNumber:numberString]) {
                        [peopleGroup addObject:person];
                    }
                }
                
                if (peopleGroup.count > 0) {
                    NSString *name = [self nameForPeople:peopleGroup];
                    number(name, numberString);
                }
            }
        }
        if (completion) {
            completion((error == nil), error);
        }
    }];
    
    
}

+(void)formattedNameForNumber:(NSString *)number
                   completion:(void (^)(NSString *name, NSError *error))completion
{
    [self fetchPeopleWithNumber:number completion:^(NSArray *people, NSError *error) {
        NSString *name = [self nameForPeople:people];
        if (!name) {
            name = number.formattedPhoneNumber;
        }
        
        if (completion) {
            completion(name, error);
        }
    }];
}


@end

