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

#import "JCAggregateFetchedResultsController.h"
#import "JCGroupDataSource.h"

@interface JCContactsFetchedResultsController : JCAggregateFetchedResultsController

-(instancetype)initWithSearchText:(NSString *)searchText
                  sortDescriptors:(NSArray *)sortDescriptors
               sectionNameKeyPath:(NSString *)sectionNameKeyPath
                              pbx:(PBX *)pbx
                            group:(id<JCGroupDataSource>)group;

@property (nonatomic, readonly) id<JCGroupDataSource> group;

@end