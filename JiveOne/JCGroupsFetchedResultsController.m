//
//  JCGroupsFetchedResultsController.m
//  JiveOne
//
//  Created by Robert Barclay on 6/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCGroupsFetchedResultsController.h"

#import "PBX.h"
#import "JCPhoneBook.h"
#import "ContactGroup.h"
#import "InternalExtensionGroup.h"

@interface JCGroupsFetchedResultsController ()
{
    PBX *_pbx;
    
    // Data Sources
    NSFetchedResultsController *_contactGroupsFetchedResultsController;
    NSFetchedResultsController *_internalExtenstionsFetchedResultsController;
    
    JCAddressBook *_addressBook;
}

@end

@implementation JCGroupsFetchedResultsController

-(instancetype)initWithSearchText:(NSString *)searchText
                  sortDescriptors:(NSArray *)sortDescriptors
                              pbx:(PBX *)pbx
               sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    return [self initWithSearchText:searchText
                    sortDescriptors:sortDescriptors
                                pbx:pbx
                 sectionNameKeyPath:sectionNameKeyPath
                        addressBook:[JCPhoneBook sharedPhoneBook].addressBook];
}

-(instancetype)initWithSearchText:(NSString *)searchText
                  sortDescriptors:(NSArray *)sortDescriptors
                              pbx:(PBX *)pbx sectionNameKeyPath:(NSString *)sectionNameKeyPath
                      addressBook:(JCAddressBook *)addressBook
{
    self = [super initWithSearchText:searchText
                     sortDescriptors:sortDescriptors
                  sectionNameKeyPath:sectionNameKeyPath
                managedObjectContext:pbx.managedObjectContext];
    
    if (self)
    {
        _pbx = pbx;
        _addressBook = addressBook;
        
        // Contacts are tied to the user. We only want contacts that are tied to the current user.
        NSFetchRequest *request = [ContactGroup MR_requestAllInContext:self.managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user = %@", pbx.user];
        if (searchText && searchText.length > 0) {
            NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@)", searchText]; // OR ( contacts.phoneNumbers.number CONTAINS[cd] %@) OR ( contacts.name CONTAINS[cd] %@)", searchText, searchText, searchText];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, searchPredicate]];
        }
        request.predicate = predicate;
        request.sortDescriptors = self.fetchRequest.sortDescriptors;
        request.fetchBatchSize = self.fetchRequest.fetchBatchSize;
        _contactGroupsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                     managedObjectContext:self.managedObjectContext
                                                                                       sectionNameKeyPath:nil
                                                                                                cacheName:nil];
        
        _contactGroupsFetchedResultsController.delegate = self;
        
        // Contacts are tied to the user. We only want contacts that are tied to the current user.
        request = [InternalExtensionGroup MR_requestAllInContext:self.managedObjectContext];
        predicate = [NSPredicate predicateWithFormat:@"ANY internalExtensions.pbx = [cd]%@", pbx];
        if (searchText && searchText.length > 0) {
            NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@)", searchText]; // OR ( internalExtensions.number CONTAINS[cd] %@) OR ( internalExtensions.name CONTAINS[cd] %@)", searchText, searchText, searchText];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, searchPredicate]];
        }
        request.predicate = predicate;
        request.sortDescriptors = self.fetchRequest.sortDescriptors;
        request.fetchBatchSize = self.fetchRequest.fetchBatchSize;
        _internalExtenstionsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                           managedObjectContext:self.managedObjectContext
                                                                                             sectionNameKeyPath:nil
                                                                                                      cacheName:nil];
        
        _internalExtenstionsFetchedResultsController.delegate = self;
        
    }
    return self;
}

- (BOOL)performFetch:(NSError **)error
{
    BOOL result = [_contactGroupsFetchedResultsController performFetch:error];
    if (!result) {
        return NO;
    }
    
    result = [_internalExtenstionsFetchedResultsController performFetch:error];
    if (!result) {
        return NO;
    }
    
    // Retrive and sort all the fetched objects.
    NSMutableArray *fetchedObjects = [NSMutableArray new];
    [fetchedObjects addObjectsFromArray:_contactGroupsFetchedResultsController.fetchedObjects];
    [fetchedObjects addObjectsFromArray:_internalExtenstionsFetchedResultsController.fetchedObjects];
    
//    NSFetchRequest *fetchRequest = self.fetchRequest;
//    NSPredicate *predicate = nil;
//    NSString *searchText = self.searchText;
//    if (searchText) {
//        predicate = [NSPredicate predicateWithBlock:^BOOL(JCAddressBookPerson *evaluatedObject, NSDictionary *bindings) {
//            BOOL found = FALSE;
//            NSString *localizedSearch = [searchText lowercaseStringWithLocale:searchText.locale];
//            NSString *localizedName = [evaluatedObject.name lowercaseStringWithLocale:searchText.locale];
//            if ([localizedName rangeOfString:localizedSearch].location != NSNotFound) {
//                found = TRUE;
//            }
//            
//            NSArray *phoneNumbers = evaluatedObject.phoneNumbers;
//            for (JCAddressBookNumber *phoneNumber in phoneNumbers) {
//                if ([phoneNumber.number rangeOfString:searchText.numericStringValue].location != NSNotFound) {
//                    found = TRUE;
//                }
//            }
//            return found;
//        }];
//    }
//    
//    NSArray *people = [_addressBook fetchPeopleWithPredicate:predicate sortDescriptors:fetchRequest.sortDescriptors];
//    [fetchedObjects addObjectsFromArray:people];
    
    self.fetchedObjects = fetchedObjects;
    return YES;
}

@end
