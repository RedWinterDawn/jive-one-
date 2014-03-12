//
//  ContactGroup.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ContactGroup : NSManagedObject

@property (nonatomic, retain) id clientEntities;
@property (nonatomic, retain) NSString * groupName;

@end
