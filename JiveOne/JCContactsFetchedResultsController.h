//
//  JCContactsFetchedResultsController.h
//  JiveOne
//
//  This objects acts as a wrapper around getting a list of phone numbers from Extensions, Contacts,
//  and the Local Address Book.
//
//  Created by Robert Barclay on 6/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "JCPhoneNumberDataSource.h"

@protocol JCContactsFetchedResultsControllerDelegate;

@interface JCContactsFetchedResultsController : NSFetchedResultsController

-(instancetype)initWithSearchText:(NSString *)searchText sortDescriptors:(NSArray *)sortDescriptors pbx:(PBX *)pbx sectionNameKeyPath:(NSString *)sectionNameKeyPath;

- (id <JCPhoneNumberDataSource> )objectAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForObject:(id<JCPhoneNumberDataSource>)object;

@end