//
//  ContactGroup.h
//  JiveOne
//
//  Created by Ethan Parker on 2/26/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ContactGroup : NSManagedObject

@property (nonatomic, retain) NSString * groupName;
@property (nonatomic, retain) id clientEntities;

@end
