//
//  LineConfiguration.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Line;

@interface LineConfiguration : NSManagedObject

// Attributes
@property (nonatomic, retain) NSString * display;
@property (nonatomic, retain) NSString * outboundProxy;
@property (nonatomic, retain) NSString * registrationHost;
@property (nonatomic, retain) NSString * sipUsername;
@property (nonatomic, retain) NSString * sipPassword;

// Relationships
@property (nonatomic, retain) Line *line;

@end
