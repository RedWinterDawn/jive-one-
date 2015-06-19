//
//  JCFile.m
//  JiveOne
//
//  Created by Robert Barclay on 6/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCFile.h"
#import "JCTranslationUnit.h"

@interface JCFile ()
{
    NSMutableArray *_translationUnits;
}

@end

@implementation JCFile

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if(self = [super init])
    {
        _dataType = [dictionary valueForKey:@"_datatype"];
        _original = [dictionary valueForKey:@"_original"];
        _sourceLanguage = [dictionary valueForKey:@"_source-language"];
        _targetLanguage = [dictionary valueForKey:@"_target-language"];
        
        NSDictionary *body = [dictionary objectForKey:@"body"];
        NSArray *transUnitsData = [body objectForKey:@"trans-unit"];
        _translationUnits = [NSMutableArray arrayWithCapacity:transUnitsData.count];
        for (id transUnitData in transUnitsData) {
            if([transUnitData isKindOfClass:[NSDictionary class]]){
                [_translationUnits addObject:[[JCTranslationUnit alloc] initWithDictionary:transUnitData]];
            }
        }
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ -> %@ %@", _sourceLanguage, _targetLanguage, _original];
}

@end
