//
//  JiveContact.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberManagedObject.h"

@class Line, PBX;

@interface Extension : JCPhoneNumberManagedObject

@property (nonatomic, retain) NSString *jrn;
@property (nonatomic, retain) NSString *pbxId;

@property (nonatomic) BOOL hidden;

@end

@interface Extension (Search)

+(Extension *)extensionForNumber:(NSString *)number onPbx:(PBX *)pbx excludingLine:(Line *)line;

+(Extension *)extensionForNumber:(NSString *)number onPbx:(PBX *)pbx;


@end