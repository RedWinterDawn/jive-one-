//
//  JCCoreDataTestDataFactory.h
//  JiveOne
//
//  Created by Robert Barclay on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;
@import CoreData;

#import <MagicalRecord/MagicalRecord.h>

@interface JCCoreDataTestDataFactory : NSObject

+ (void)loadTestCoreDataTestDataOnContext:(NSManagedObjectContext *)context;

@end
