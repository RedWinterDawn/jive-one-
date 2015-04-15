//
//  JiveContact.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Person.h"

@class Line;

@interface JiveContact : Person

@property (nonatomic, retain) NSString * extension;
@property (nonatomic, retain) NSString * jrn;

// Transient
@property (nonatomic, retain) NSString * pbxId;

@end

@interface JiveContact (Search)

+(JiveContact *)jiveContactWithExtension:(NSString *)number
                                 forLine:(Line *)line;

@end