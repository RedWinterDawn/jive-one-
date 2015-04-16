//
//  JiveContact.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonManagedObject.h"

@class Line;

@interface Extension : JCPersonManagedObject

@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * pbxId;

@end

@interface Extension (Search)

+(Extension *)jiveContactWithExtension:(NSString *)number
                                 forLine:(Line *)line;

@end