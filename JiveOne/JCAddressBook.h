//
//  JCAddressBook.h
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "JCAddressBookPerson.h"

@interface JCAddressBook : NSObject

+(void)personForPersonId:(NSString *)personId
              personHash:(NSString *)hash
              completion:(void (^)(JCAddressBookPerson *person, NSError *error))completion;

+(void)personForRecordId:(ABRecordID)recordId
              personHash:(NSString *)hash
              completion:(void (^)(JCAddressBookPerson *person, NSError *error))completion;

+(void)fetchAllPeople:(void (^)(NSArray *people, NSError *error))completion;

+(void)fetchAllPeopleWithSortDescriptors:(NSArray *)sortDescriptors
                              completion:(void (^)(NSArray *people, NSError *error))completion;

+(void)fetchWithKeyword:(NSString *)keyword
        sortDescriptors:(NSArray *)sortDescriptors
             completion:(void (^)(NSArray *people, NSError *error))completion;

+(void)fetchWithPredicate:(NSPredicate *)predicate
          sortDescriptors:(NSArray *)sortDescriptors
               completion:(void (^)(NSArray *people, NSError *error))completion;

@end
