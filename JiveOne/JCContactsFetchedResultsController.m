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

-(instancetype)initWithName:(NSString *)name;
-(void)addObject:(id)object;
-(BOOL)containsObject:(id)object;
-(void)deleteObject:(id)object;

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
}

@end

@implementation JCContactsFetchedResultsController

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
    self = [super init];
    if (self) {
        _fetchRequest = fetchRequest;
        _pbx = pbx;
        _managedObjectContext = pbx.managedObjectContext;
        _sectionNameKeyPath = sectionNameKeyPath;
        
        // Contacts are tied to the user. We only want contacts that are tied to the current user.
        NSFetchRequest *request = [Contact MR_requestAllInContext:_managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user = %@", pbx.user];
        if (fetchRequest.predicate) {
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, fetchRequest.predicate]];
        }
        request.predicate = predicate;
        request.sortDescriptors = fetchRequest.sortDescriptors;
        request.fetchBatchSize = fetchRequest.fetchBatchSize;
        _contactsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                managedObjectContext:_managedObjectContext
                                                                                  sectionNameKeyPath:nil
                                                                                           cacheName:nil];
        _contactsFetchedResultsController.delegate = self;
        
        // Extensions. We only want extensions that are part of our pbx and are not hidden.
        request = [Extension MR_requestAllInContext:_managedObjectContext];
        predicate = [NSPredicate predicateWithFormat:@"pbxId = %@ && hidden = %@", pbx.pbxId, @NO];
        if (fetchRequest.predicate) {
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, fetchRequest.predicate]];
        }
        request.predicate = predicate;
        request.sortDescriptors = fetchRequest.sortDescriptors;
        request.fetchBatchSize = fetchRequest.fetchBatchSize;
        _extensionsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                  managedObjectContext:_managedObjectContext
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
    [_fetchedObjects sortUsingDescriptors:_fetchRequest.sortDescriptors];
    
    _sections = [NSMutableArray new];
    for (id<JCPhoneNumberDataSource> contact in _fetchedObjects)
    {
        // Fetch the section name from the object.
        NSString *sectionName;
        if ([contact isKindOfClass:[NSManagedObject class]])
        {
            NSManagedObject *object = (NSManagedObject *)contact;
            sectionName = [object valueForKeyPath:_sectionNameKeyPath];
        }
        else
        {
            SEL sectionNameKeyPath = NSSelectorFromString(_sectionNameKeyPath);
            if ([contact respondsToSelector:sectionNameKeyPath]) {
                id object = [contact performSelector:sectionNameKeyPath];
                if ([object isKindOfClass:[NSString class]]) {
                    sectionName = object;
                }
            }
        }
        
        // Get the section for the give named section.
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
    return nil;
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

#pragma mark - Delegate Handlers -

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    
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
    
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    
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

- (NSString *)description
{
    NSMutableString *string = [NSMutableString stringWithFormat:@"Section Name: %@", _name];
    [string appendFormat:@"%@", [_objects description]];
    return string;
}

@end
