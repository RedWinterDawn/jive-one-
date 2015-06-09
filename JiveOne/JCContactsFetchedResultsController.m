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

@interface JCContactsSectionInfo : NSObject <NSFetchedResultsSectionInfo> {
    NSMutableArray *_objects;
    NSString *_name;
    
}

- (instancetype)initWithName:(NSString *)name;
- (void)addObject:(id)object;
- (void)addObject:(id)object sortUsingDescriptors:(NSArray *)sortDescriptors;

- (BOOL)containsObject:(id)object;
- (void)deleteObject:(id)object;

@end

@interface JCContactsFetchedResultsController () <NSFetchedResultsControllerDelegate> {
    
    NSMutableArray *_fetchedObjects;
    NSMutableArray *_sections;
    NSMutableArray *_sectionIndexTitles;
    
    PBX *_pbx;
    
    // Data Sources
    NSFetchedResultsController *_contactsFetchedResultsController;
    NSFetchedResultsController *_extensionsFetchedResultsController;
    JCAddressBook *_addressBook;
    
    BOOL _updatingContent;
}

@end

@implementation JCContactsFetchedResultsController

@dynamic delegate;

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest
                                 pbx:(PBX *)pbx
                  sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    return [self initWithFetchRequest:fetchRequest
                                  pbx:pbx sectionNameKeyPath:sectionNameKeyPath
                          addressBook:[JCPhoneBook sharedPhoneBook].addressBook];
}

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest
                                 pbx:(PBX *)pbx
                  sectionNameKeyPath:(NSString *)sectionNameKeyPath
                         addressBook:(JCAddressBook *)addressBook
{
    self = [super initWithFetchRequest:fetchRequest managedObjectContext:pbx.managedObjectContext sectionNameKeyPath:sectionNameKeyPath cacheName:nil];
    if (self) {
        _pbx = pbx;
        _addressBook = addressBook;
        
        // Contacts are tied to the user. We only want contacts that are tied to the current user.
        NSFetchRequest *request = [Contact MR_requestAllInContext:self.managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user = %@", pbx.user];
        if (fetchRequest.predicate) {
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, fetchRequest.predicate]];
        }
        request.predicate = predicate;
        request.sortDescriptors = fetchRequest.sortDescriptors;
        request.fetchBatchSize = fetchRequest.fetchBatchSize;
        _contactsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                managedObjectContext:self.managedObjectContext
                                                                                  sectionNameKeyPath:nil
                                                                                           cacheName:nil];
        _contactsFetchedResultsController.delegate = self;
        
        // Extensions. We only want extensions that are part of our pbx and are not hidden.
        request = [Extension MR_requestAllInContext:self.managedObjectContext];
        predicate = [NSPredicate predicateWithFormat:@"pbxId = %@ && hidden = %@", pbx.pbxId, @NO];
        if (fetchRequest.predicate) {
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, fetchRequest.predicate]];
        }
        request.predicate = predicate;
        request.sortDescriptors = fetchRequest.sortDescriptors;
        request.fetchBatchSize = fetchRequest.fetchBatchSize;
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
    _fetchedObjects = [NSMutableArray new];
    [_fetchedObjects addObjectsFromArray:_contactsFetchedResultsController.fetchedObjects];
    [_fetchedObjects addObjectsFromArray:_extensionsFetchedResultsController.fetchedObjects];
    
    NSFetchRequest *fetchRequest = self.fetchRequest;
    NSArray *people = [_addressBook fetchPeopleWithPredicate:fetchRequest.predicate sortDescriptors:fetchRequest.sortDescriptors];
    [_fetchedObjects addObjectsFromArray:people];
    
    [_fetchedObjects sortUsingDescriptors:self.fetchRequest.sortDescriptors];
    
    _sections = [NSMutableArray new];
    for (id<JCPhoneNumberDataSource> contact in _fetchedObjects)
    {
        NSString *sectionName = [self sectionNameForObject:contact];
        JCContactsSectionInfo *sectionInfo = [self sectionForName:sectionName];
        if (!sectionInfo) {
            sectionInfo = [[JCContactsSectionInfo alloc] initWithName:sectionName];
            [_sections addObject:sectionInfo];
        }
        [sectionInfo addObject:contact];
    }
    return YES;
}

- (id <JCPhoneNumberDataSource> )objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}

- (NSIndexPath *)indexPathForObject:(id<JCPhoneNumberDataSource>)object
{
    NSString *sectionName = [self sectionNameForObject:object];
    if (!sectionName) {
        return nil;
    }
    
    JCContactsSectionInfo *sectionInfo = [self sectionForName:sectionName];
    if (!sectionInfo) {
        return nil;
    }
    
    NSInteger section = [_sections indexOfObject:sectionInfo];
    if (![sectionInfo containsObject:object]) {
        return nil;
    }
    
    NSInteger row = [sectionInfo.objects indexOfObject:object];
    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (NSArray *)sectionIndexTitles
{
    NSMutableArray *sectionIndexTitles = [NSMutableArray new];
    for (JCContactsSectionInfo *sectionInfo in _sections) {
        [sectionIndexTitles addObject:sectionInfo.indexTitle];
    }
    return sectionIndexTitles;
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName
{
    JCContactsSectionInfo *sectionInfo = [self sectionForName:sectionName];
    if (sectionInfo) {
        return sectionInfo.indexTitle;
    }
    return nil;
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex
{
    NSUInteger section = 0;
    for(JCContactsSectionInfo *sectionInfo in _sections) {
        if([sectionInfo.indexTitle isEqualToString:title]) {
            return section;
        }
        ++section;
    }
    return section;
}

-(NSArray *)fetchedObjects
{
    return _fetchedObjects;
}

-(NSArray *)sections
{
    return _sections;
}

#pragma mark - Delegate Handlers -

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // If we are already updating the content, end the earlier update batch before we start the next
    if (_updatingContent) {
        [self.delegate controllerDidChangeContent:self];
    }
    
    _updatingContent = TRUE;
    [self.delegate controllerWillChangeContent:self];
}

- (void)controller:(NSFetchedResultsController *)controller
 didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
          atIndex:(NSUInteger)sectionIndex
    forChangeType:(NSFetchedResultsChangeType)type
{
    
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeObject:(id)anObject
      atIndexPath:(NSIndexPath *)indexPath
    forChangeType:(NSFetchedResultsChangeType)type
     newIndexPath:(NSIndexPath *)newIndexPath
{
    if (![anObject isKindOfClass:[NSManagedObject class]]) {
        return;
    }
    
    // Get the section for the managed object. Determine if we have a section.
    NSManagedObject *managedObject = (NSManagedObject *)anObject;
    NSString *sectionName = [managedObject valueForKeyPath:self.sectionNameKeyPath];
    NSInteger section;
    JCContactsSectionInfo *sectionInfo = [self sectionForName:sectionName];
    if (!sectionInfo) {
        sectionInfo = [[JCContactsSectionInfo alloc] initWithName:sectionName];
        [_sections addObject:sectionInfo];
        [_sections sortUsingDescriptors:self.fetchRequest.sortDescriptors];
        section = [_sections indexOfObject:sectionInfo];
        [self.delegate controller:self didChangeSection:sectionInfo atIndex:section forChangeType:NSFetchedResultsChangeInsert];
    } else {
        section = [_sections indexOfObject:sectionInfo];
    }
    
    NSInteger row;
    switch (type) {
        case NSFetchedResultsChangeInsert:
        {
            [sectionInfo addObject:managedObject sortUsingDescriptors:self.fetchRequest.sortDescriptors];
            row = [sectionInfo.objects indexOfObject:managedObject];
            indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            [self.delegate controller:self didChangeObject:anObject atIndexPath:nil forChangeType:type newIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            row = [sectionInfo.objects indexOfObject:managedObject];
            [sectionInfo deleteObject:managedObject];
            if (sectionInfo.numberOfObjects == 0) {
                [_sections removeObject:sectionInfo];
                [self.delegate controller:self didChangeSection:sectionInfo atIndex:section forChangeType:type];
            } else {
                indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                [self.delegate controller:self didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:nil];
            }
            break;
        }
        case NSFetchedResultsChangeUpdate:
        {
            row = [sectionInfo.objects indexOfObject:managedObject];
            indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            [self.delegate controller:self didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:indexPath];
            break;
        }
        
        case NSFetchedResultsChangeMove:
        {
            indexPath = [self indexPathForObject:anObject]; // Get the old indexPath.
            
            // Check to see if we changed sections, if so, we need to remove it from the old
            // section, and add it to the new section.
            if (indexPath.section != section) {
                JCContactsSectionInfo *oldSectionInfo = [_sections objectAtIndex:indexPath.section];
                [oldSectionInfo deleteObject:anObject];
                if (oldSectionInfo.numberOfObjects == 0) {
                    [_sections removeObject:sectionInfo];
                    [self.delegate controller:self didChangeSection:sectionInfo atIndex:section forChangeType:type];
                } else {
                    [sectionInfo addObject:anObject];
                }
            }
            row = [sectionInfo.objects indexOfObject:anObject];
            newIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
            [self.delegate controller:self didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
        }
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (_updatingContent) {
        [self.delegate controllerDidChangeContent:self];
        _updatingContent = FALSE;
    }
}

#pragma mark - Private -

- (JCContactsSectionInfo *)sectionForName:(NSString *)name
{
    for (JCContactsSectionInfo *sectionInfo in _sections) {
        if ([sectionInfo.name isEqualToString:name]) {
            return sectionInfo;
        }
    }
    return nil;
}

-(NSString *)sectionNameForObject:(id<JCPhoneNumberDataSource>)phoneNumber
{
    if ([phoneNumber isKindOfClass:[NSManagedObject class]]) {
        return [(NSManagedObject *)phoneNumber valueForKeyPath:self.sectionNameKeyPath];
    }
    
    SEL sectionNameKeyPath = NSSelectorFromString(self.sectionNameKeyPath);
    if ([phoneNumber respondsToSelector:sectionNameKeyPath]) {
        id object = [phoneNumber performSelector:sectionNameKeyPath];
        if ([object isKindOfClass:[NSString class]]) {
            return object;
        }
    }
    return nil;
}

@end

@implementation JCContactsSectionInfo

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _name = name;
        _objects = [NSMutableArray new];
    }
    return self;
}

- (NSString *)name
{
    return _name;
}

- (NSString *)indexTitle;
{
    NSString *name = self.name;
    if (name.length > 0) {
        return [[name substringToIndex:1] uppercaseStringWithLocale:name.locale];
    }
    return nil;
}

- (NSUInteger)numberOfObjects
{
    return _objects.count;
}

- (NSArray *)objects
{
    return _objects;
}

- (void)addObject:(id)object
{
    if (![self containsObject:object]) {
        [_objects addObject:object];
    }
}

- (void)addObject:(id)object sortUsingDescriptors:(NSArray *)sortDescriptors
{
    [self addObject:object];
    [_objects sortUsingDescriptors:sortDescriptors];
}

- (BOOL)containsObject:(id)object
{
    return [_objects containsObject:object];
}

- (void)deleteObject:(id)object
{
    if ([self containsObject:object]) {
        [_objects removeObject:object];
    }
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [_objects objectAtIndex:index];
}

@end
