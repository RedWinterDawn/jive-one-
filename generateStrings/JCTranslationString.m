//
//  JCTranslationString.m
//  JiveOne
//
//  Created by Robert Barclay on 6/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCTranslationString.h"

@interface JCTranslationString ()
{
    NSMutableArray *_translationStrings;
}

@end

@implementation JCTranslationString

-(instancetype) initWithSource:(NSString *)source target:(NSString *)target note:(NSString *)note
{
    if (self = [super init]) {
        _source = [self escapeString:source];
        _target = [self escapeString:target];
        _note = note;
        
        _translationStrings = [NSMutableArray new];
    }
    return self;
}

-(void)addTranslationString:(JCTranslationString *)translationString
{
    if (translationString) {
        [_translationStrings addObject:translationString];
    }
}

-(BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[JCTranslationString class]]) {
        return NO;
    }
    
    JCTranslationString *string = (JCTranslationString *)object;
    if ([_source.lowercaseString isEqualToString:string.source.lowercaseString]) {
        return YES;
    }
    return NO;
}

-(BOOL)isEqualTo:(id)object
{
    if (![object isKindOfClass:[JCTranslationString class]]) {
        return NO;
    }
    
    JCTranslationString *string = (JCTranslationString *)object;
    if ([_source.lowercaseString isEqualToString:string.source.lowercaseString]) {
        return YES;
    }
    return NO;
}


-(NSString *)description
{
    NSString *target = _target ? _target : _source;
    return [NSString stringWithFormat:@"/* %@ */ \n\"%@\" = \"%@\";\n\n", _note, _source, target];
}

-(NSString *)escapeString:(NSString *)string
{
    return [string stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
}

@end
