//
//  ContactGroup.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Group.h"

@class InternalExtension;

@interface InternalExtensionGroup : Group;

@property (nonatomic, retain) NSSet *internalExtensions;

@end

@interface InternalExtensionGroup (CoreDataGeneratedAccessors)

- (void)addInternalExtensionsObject:(InternalExtension *)value;
- (void)removeInternalExtensionsObject:(InternalExtension *)value;
- (void)addInternalExtensions:(NSSet *)values;
- (void)removeInternalExtensions:(NSSet *)values;

@end