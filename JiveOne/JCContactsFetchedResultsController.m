//
//  JCContactsFetchedResultsController.m
//  JiveOne
//
//  Created by Robert Barclay on 6/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsFetchedResultsController.h"

#import "PBX.h"
#import "Extension.h"
#import "Contact.h"
#import "JCPhoneBook.h"

@interface JCContactsFetchedResultsController () {
    PBX *_pbx;
    
    // Data Sources
    NSFetchedResultsController *_contactsFetchedResultsController;
    NSFetchedResultsController *_extensionsFetchedResultsController;
    JCAddressBook *_addressBook;
}

@end

@implementation JCContactsFetchedResultsController

@dynamic delegate;

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
    
    if (self) {
        _pbx = pbx;
        _addressBook = addressBook;
        
        // Contacts are tied to the user. We only want contacts that are tied to the current user.
        NSFetchRequest *request = [Contact MR_requestAllInContext:self.managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user = %@", pbx.user];
        if (searchText && searchText.length > 0) {
            NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"((name contains[cd] %@) OR ( phoneNumbers.number contains[cd] %@))", searchText, searchText];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, searchPredicate]];
        }
        request.predicate = predicate;
        request.sortDescriptors = self.fetchRequest.sortDescriptors;
        request.fetchBatchSize = self.fetchRequest.fetchBatchSize;
        _contactsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                managedObjectContext:self.managedObjectContext
                                                                                  sectionNameKeyPath:nil
                                                                                           cacheName:nil];
        _contactsFetchedResultsController.delegate = self;
        
        // Extensions. We only want extensions that are part of our pbx and are not hidden.
        request = [Extension MR_requestAllInContext:self.managedObjectContext];
        predicate = [NSPredicate predicateWithFormat:@"pbxId = %@ && hidden = %@", pbx.pbxId, @NO];
        if (searchText && searchText.length > 0) {
            NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"((name contains[cd] %@) OR ( number contains[cd] %@))", searchText, searchText];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, searchPredicate]];
        }
        request.predicate = predicate;
        request.sortDescriptors = self.fetchRequest.sortDescriptors;
        request.fetchBatchSize = self.fetchRequest.fetchBatchSize;
        _extensionsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                  managedObjectContext:self.managedObjectContext
                                                                                    sectionNameKeyPath:nil
                                                                                             cacheName:nil];
        _contactsFetchedResultsController.delegate = self;
    }
    return self;
}

- (BOOL)performFetch:(NSError **)error
{
    BOOL result = [_contactsFetchedResultsController performFetch:error];
    if (!result) {
        return NO;
    }
    
    result = [_extensionsFetchedResultsController performFetch:error];
    if (!result) {
        return NO;
    }
    
    // Retrive and sort all the fetched objects.
    NSMutableArray *fetchedObjects = [NSMutableArray new];
    [fetchedObjects addObjectsFromArray:_contactsFetchedResultsController.fetchedObjects];
    [fetchedObjects addObjectsFromArray:_extensionsFetchedResultsController.fetchedObjects];
    
    NSFetchRequest *fetchRequest = self.fetchRequest;
    NSPredicate *predicate = nil;
    NSString *searchText = self.searchText;
    if (searchText) {
       predicate = [NSPredicate predicateWithBlock:^BOOL(JCAddressBookPerson *evaluatedObject, NSDictionary *bindings) {
            BOOL found = FALSE;
            NSString *localizedSearch = [searchText lowercaseStringWithLocale:searchText.locale];
            NSString *localizedName = [evaluatedObject.name lowercaseStringWithLocale:searchText.locale];
            if ([localizedName rangeOfString:localizedSearch].location != NSNotFound) {
                found = TRUE;
            }
            
            NSArray *phoneNumbers = evaluatedObject.phoneNumbers;
            for (JCAddressBookNumber *phoneNumber in phoneNumbers) {
                if ([phoneNumber.number rangeOfString:searchText.numericStringValue].location != NSNotFound) {
                    found = TRUE;
                }
            }
            return found;
        }];
    }
    
    NSArray *people = [_addressBook fetchPeopleWithPredicate:predicate sortDescriptors:fetchRequest.sortDescriptors];
    [fetchedObjects addObjectsFromArray:people];
    
    self.fetchedObjects = fetchedObjects;
    return YES;
}

@end

