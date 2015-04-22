//
//  JCAddressBook.h
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;
@import CoreData;

#import "JCAddressBookPerson.h"
#import "JCAddressBookNumber.h"

extern NSString *const kJCAddressBookPeople;
extern NSString *const kJCAddressBookNumbers;

extern NSString *const kJCAddressBookLoadedNotification;
extern NSString *const kJCAddressBookFailedToLoadNotification;

@interface JCAddressBook : NSObject

@property (retain, nonatomic) NSMutableSet *people;
@property (retain, nonatomic) NSMutableSet *numbers;

// Number Requests
- (NSArray *)fetchAllNumbersAscending:(BOOL)ascending;
- (NSArray *)fetchAllNumbersSortedByKey:(NSString *)sortedByKey ascending:(BOOL)ascending;
- (NSArray *)fetchNumbersWithKeyword:(NSString *)keyword sortedByKey:(NSString *)sortedByKey ascending:(BOOL)ascending;
- (NSArray *)fetchNumbersWithPredicate:(NSPredicate *)predicate sortedByKey:(NSString *)sortedByKey ascending:(BOOL)ascending;

// People Requests



// General requests
- (NSArray *)fetchWithFetchRequest:(NSFetchRequest *)request;

#pragma mark - Legacy -


- (void)personForPersonId:(NSString *)personId
              personHash:(NSString *)hash
               completion:(void (^)(JCAddressBookPerson *person, NSError *error))completion __deprecated;

- (void)personForRecordId:(ABRecordID)recordId
              personHash:(NSString *)hash
              completion:(void (^)(JCAddressBookPerson *person, NSError *error))completion __deprecated;

- (void)fetchAllPeople:(void (^)(NSArray *people, NSError *error))completion __deprecated;

- (void)fetchAllPeopleWithSortDescriptors:(NSArray *)sortDescriptors
                               completion:(void (^)(NSArray *people, NSError *error))completion __deprecated;

- (void)fetchNumbersWithKeyword:(NSString *)keyword
                     completion:(void (^)(NSArray *numbers, NSError *error))completion __deprecated;

- (void)fetchWithKeyword:(NSString *)keyword
              completion:(void (^)(NSArray *people, NSError *error))completion __deprecated;

- (void)fetchWithKeyword:(NSString *)keyword
         sortDescriptors:(NSArray *)sortDescriptors
              completion:(void (^)(NSArray *people, NSError *error))completion __deprecated;

- (void)fetchWithPredicate:(NSPredicate *)predicate
           sortDescriptors:(NSArray *)sortDescriptors
                completion:(void (^)(NSArray *people, NSError *error))completion __deprecated;

- (void)fetchPeopleWithNumber:(NSString *)number
                   completion:(void (^)(NSArray *people, NSError *error))completion __deprecated;

- (void)fetchPeopleWithNumbers:(NSSet *)numbers
                    completion:(void (^)(NSArray *people, NSError *error))completion __deprecated;

@end

@interface JCAddressBook (FormattedNames)

- (void)formattedNamesForNumbers:(NSSet *)numbers
                           begin:(void (^)())begin
                          number:(void (^)(NSString *name, NSString *number))number
                      completion:(void(^)(BOOL success, NSError *error))completion __deprecated;

- (void)formattedNameForNumber:(NSString *)number
                    completion:(void (^)(NSString *name, NSError *error))completion __deprecated;

@end
