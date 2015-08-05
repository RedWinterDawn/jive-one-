//
//  JCGroupsFetchedResultsController.h
//  JiveOne
//
//  Created by Robert Barclay on 6/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAggregateFetchedResultsController.h"

@interface JCGroupsFetchedResultsController : JCAggregateFetchedResultsController

-(instancetype)initWithSearchText:(NSString *)searchText
                  sortDescriptors:(NSArray *)sortDescriptors
                              pbx:(PBX *)pbx
               sectionNameKeyPath:(NSString *)sectionNameKeyPath;

@end
