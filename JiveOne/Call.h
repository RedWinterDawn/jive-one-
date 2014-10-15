//
//  Call.h
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "RecentEvent.h"
#import "JCLineSession.h"

@protocol Call <NSObject>

@optional
@property (nonatomic, readonly) UIImage *icon;

@end

@interface Call : RecentEvent <Call>

@property (nonatomic, retain) NSString *number;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *extension;

@end

@interface Call (MagicalRecord)

+(void)addCallEntity:(NSString *)entityName lineSession:(JCLineSession *)session;

@end