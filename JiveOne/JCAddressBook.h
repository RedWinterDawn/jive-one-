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
- (NSArray *)fetchNumbersWithPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber sortedByKey:(NSString *)sortedByKey ascending:(BOOL)ascending;
- (NSArray *)fetchNumbersWithPredicate:(NSPredicate *)predicate sortedByKey:(NSString *)sortedByKey ascending:(BOOL)ascending;

// People Requests

// General requests
- (NSArray *)fetchWithFetchRequest:(NSFetchRequest *)request;

@end
