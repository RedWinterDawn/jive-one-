//
//  JCAddressBook.m
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import AddressBook;

#import "JCAddressBook.h"
#import "JCAddressBookNumber.h"
#import "PhoneNumber.h"

NSString *const kJCAddressBookPeople    = @"JCAddressBookPeople";
NSString *const kJCAddressBookNumbers   = @"JCAddressBookNumbers";

NSString *const kJCAddressBookLoadedNotification = @"AddressBookLoadedNotification";
NSString *const kJCAddressBookFailedToLoadNotification = @"AddressBookFailedToLoadNotification";

@implementation JCAddressBook

- (instancetype)initWithPeople:(NSSet *)people numbers:(NSSet *)numbers
{
    self = [super init];
    if (self) {
        _people   = people.mutableCopy;
        _numbers  = numbers.mutableCopy;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self getPermission:^(BOOL success, ABAddressBookRef addressBookRef, NSError *error) {
            if (success) {
                NSDictionary *results = [self processAddressBook:addressBookRef];
                self.people = [results objectForKey:kJCAddressBookPeople];
                self.numbers = [results objectForKey:kJCAddressBookNumbers];
                [[NSNotificationCenter defaultCenter] postNotificationName:kJCAddressBookLoadedNotification
                                                                    object:self
                                                                  userInfo:nil];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kJCAddressBookFailedToLoadNotification
                                                                    object:self
                                                                  userInfo:error.userInfo];
            }
        }];
    }
    return self;
}

- (void)dealloc
{
    _people = nil;
    _numbers = nil;
}

#pragma mark - Public -

#pragma mark Number Requests

- (NSArray *)fetchAllNumbersAscending:(BOOL)ascending
{
    return [self fetchAllNumbersSortedByKey:NSStringFromSelector(@selector(number)) ascending:ascending];
}

- (NSArray *)fetchAllNumbersSortedByKey:(NSString *)sortedByKey ascending:(BOOL)ascending
{
    return [self fetchNumbersWithKeyword:nil sortedByKey:sortedByKey ascending:ascending];
}

- (NSArray *)fetchNumbersWithKeyword:(NSString *)keyword sortedByKey:(NSString *)sortedByKey ascending:(BOOL)ascending
{
    NSPredicate *predicate = nil;
    if (keyword) {
        predicate = [NSPredicate predicateWithBlock: ^BOOL(JCAddressBookNumber *entity, NSDictionary *bindings) {
            return [entity containsKeyword:keyword];
        }];
    }
    return [self fetchNumbersWithPredicate:predicate sortedByKey:sortedByKey ascending:ascending];
}

- (NSArray *)fetchNumbersWithPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber sortedByKey:(NSString *)sortedByKey ascending:(BOOL)ascending
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(JCAddressBookNumber *entity, NSDictionary *bindings) {
        return [entity isEqualToPhoneNumber:phoneNumber];
    }];
    return [self fetchNumbersWithPredicate:predicate sortedByKey:sortedByKey ascending:ascending];
}

- (NSArray *)fetchNumbersWithPredicate:(NSPredicate *)predicate sortedByKey:(NSString *)sortedByKey ascending:(BOOL)ascending
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kJCAddressBookNumbers];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:sortedByKey ascending:ascending]];
    if (sortedByKey) {
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:sortedByKey ascending:ascending]];
    }
    if (predicate) {
        fetchRequest.predicate = predicate;
    }
    return [self fetchWithFetchRequest:fetchRequest];
}

#pragma mark People Requests

- (NSArray *)fetchPeopleWithPredicate:(NSPredicate *)predicate sortedByKey:(NSString *)sortedByKey ascending:(BOOL)ascending;
{
    NSArray *sortDescriptors;
    if (sortedByKey) {
        sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:sortedByKey ascending:ascending]];
        
    }
    return [self fetchPeopleWithPredicate:predicate sortDescriptors:sortDescriptors];
}

- (NSArray *)fetchPeopleWithPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sorteDescriptors;
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kJCAddressBookPeople];
    if (sorteDescriptors) {
        fetchRequest.sortDescriptors = sorteDescriptors;
    }
    if (predicate) {
        fetchRequest.predicate = predicate;
    }
    return [self fetchWithFetchRequest:fetchRequest];
}

#pragma mark General Requests

-(NSArray *)fetchWithFetchRequest:(NSFetchRequest *)request
{
    NSMutableSet *entities = [self entitiesForKey:request.entityName];
    if (request.predicate) {
        [entities filterUsingPredicate:request.predicate];
    }
    if (request.sortDescriptors) {
        return [entities sortedArrayUsingDescriptors:request.sortDescriptors];
    }
    return entities.allObjects;
}

#pragma mark - Private -

-(NSMutableSet *)entitiesForKey:(NSString *)key {
    if ([key isEqualToString:kJCAddressBookNumbers]) {
        return self.numbers.mutableCopy;
    } else  {
        return self.people.mutableCopy;
    }
}


/**
 * Parses an ABAddressBookRef into arrays of JCAddressBookPerson, JCAddressBookNumbers for search 
 * retrival.
 */
- (NSDictionary *)processAddressBook:(ABAddressBookRef)addressBookRef
{
    NSMutableSet *people = [NSMutableSet new];
    NSMutableSet *numbers = [NSMutableSet new];
    
    @autoreleasepool {
        NSArray *allSources = (__bridge NSArray *)ABAddressBookCopyArrayOfAllSources(addressBookRef);
        for (int i = 0; i < allSources.count; i++) {
            ABRecordRef source = (__bridge ABRecordRef)([allSources objectAtIndex:i]);
            NSArray *sourcePeople = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeopleInSource(addressBookRef, source);
            for (int i=0; i < sourcePeople.count; i++) {
                ABRecordRef record = (__bridge ABRecordRef)([sourcePeople objectAtIndex:i]);
                if (!record) {
                    continue;
                }
                
                JCAddressBookPerson *person = [JCAddressBookPerson addressBookPersonWithABRecordRef:record];
                if (person) {
                    [people addObject:person];
                    [numbers addObjectsFromArray:person.phoneNumbers];
                }
            }
        }
    }
    return @{kJCAddressBookPeople: people, kJCAddressBookNumbers: numbers};
}

#pragma mark - Private -

- (void)getPermission:(void (^)(BOOL success, ABAddressBookRef addressBook, NSError *error))completion
{
    CFErrorRef err;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &err);
    if (err) {
        completion(NO, NULL, nil);
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

@end