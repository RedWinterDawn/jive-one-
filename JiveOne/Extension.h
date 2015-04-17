//
//  JiveContact.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonManagedObject.h"

@class Line, PBX;

@interface Extension : JCPersonManagedObject

@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * pbxId;

@end

@interface Extension (Search)

+(Extension *)extensionForNumber:(NSString *)number onPbx:(PBX *)pbx excludingLine:(Line *)line;

@end