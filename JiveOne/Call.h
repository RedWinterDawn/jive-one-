//
//  Call.h
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "RecentLineEvent.h"
#import "JCPhoneSipSession.h"

extern NSString *const kCallEntityName;

@protocol Call <NSObject>

@optional
@property (nonatomic, readonly) UIImage *icon;

@end

@interface Call : RecentLineEvent <Call>

@end

@interface Call (MagicalRecord)

+(void)addCallEntity:(NSString *)entityName line:(Line *)line lineSession:(JCPhoneSipSession *)session read:(BOOL)read;

@end