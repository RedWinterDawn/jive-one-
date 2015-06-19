//
//  JCTranslationUnit.m
//  JiveOne
//
//  Created by Robert Barclay on 6/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCTranslationUnit.h"

@implementation JCTranslationUnit

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _identifier     = [dictionary objectForKey:@"_id"];
        _source = [dictionary objectForKey:@"source"];
        _note   = [dictionary objectForKey:@"note"];
        _target = [dictionary objectForKey:@"target"];
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ = %@", _source, _target];
}

@end
