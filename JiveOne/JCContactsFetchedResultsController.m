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

#import "ContactGroup.h"
#import "InternalExtensionGroup.h"
#import "InternalExtension.h"

@interface JCContactsFetchedResultsController () {
    PBX *_pbx;
    id <JCGroupDataSource> _group;
    
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
               sectionNameKeyPath:(NSString *)sectionNameKeyPath
                              pbx:(PBX *)pbx
                            group:(id<JCGroupDataSource>)group
{
    return [self initWithSearchText:searchText
                    sortDescriptors:sortDescriptors
                 sectionNameKeyPath:sectionNameKeyPath
                                pbx:pbx
                              group:group
                        addressBook:[JCPhoneBook sharedPhoneBook].addressBook];
}

-(instancetype)initWithSearchText:(NSString *)searchText
                  sortDescriptors:(NSArray *)sortDescriptors
               sectionNameKeyPath:(NSString *)sectionNameKeyPath
                              pbx:(PBX *)pbx
                            group:(id<JCGroupDataSource>)group
                      addressBook:(JCAddressBook *)addressBook
{
    self = [super initWithSearchText:searchText
                     sortDescriptors:sortDescriptors
                  sectionNameKeyPath:sectionNameKeyPath
                managedObjectContext:pbx.managedObjectContext];
    
    if (self) {
        _pbx = pbx;
        _addressBook = addressBook;
        _group = group;
        
        // Contacts are tied to the user. We only want contacts that are tied to the current user.
        if (!group || [_group isKindOfClass:[ContactGroup class]])
        {
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
        }
        
        // Extensions
        if (!group || [group isKindOfClass:[InternalExtensionGroup class]])
        {
            // Extensions. We only want extensions that are part of our pbx and are not hidden.
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbxId = %@ && hidden = %@", pbx.pbxId, @NO];;
            NSFetchRequest *request = nil;
            if (group) {
                request = [InternalExtension MR_requestAllInContext:self.managedObjectContext];
                NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"groups CONTAINS %@", group];
                predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, groupPredicate]];
            } else {
                request = [Extension MR_requestAllInContext:self.managedObjectContext];
                predicate = [NSPredicate predicateWithFormat:@"pbxId = %@ && hidden = %@", pbx.pbxId, @NO];
            }
            
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
            _extensionsFetchedResultsController.delegate = self;
        }
    }
    return self;
}

- (BOOL)performFetch:(NSError **)error
{
    NSMutableArray *fetchedObjects = [NSMutableArray new];
    BOOL result;
    if (_contactsFetchedResultsController) {
        result = [_contactsFetchedResultsController performFetch:error];
        [fetchedObjects addObjectsFromArray:_contactsFetchedResultsController.fetchedObjects];
        if (!result) {
            return result;
        }
    }
    
    if (_extensionsFetchedResultsController) {
        result = [_extensionsFetchedResultsController performFetch:error];
        [fetchedObjects addObjectsFromArray:_extensionsFetchedResultsController.fetchedObjects];
        if (!result) {
            return NO;
        }
    }
    
    // Retrive and sort all the fetched objects.
    if (!_group && ![_group isKindOfClass:[NSManagedObject class]]) {
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
        
        NSArray *people = [_addressBook fetchPeopleWithPredicate:predicate sortDescriptors:self.fetchRequest.sortDescriptors];
        [fetchedObjects addObjectsFromArray:people];
    }
    
    self.fetchedObjects = fetchedObjects;
    return YES;
}

@end

