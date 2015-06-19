//
//  JCDataLoader.m
//  JiveOne
//
//  Created by Robert Barclay on 6/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCDataLoader.h"
#import "XMLDictionary.h"
#import "JCFile.h"
#import "JCTranslationUnit.h"
#import "JCTranslationString.h"

@interface JCDataLoader ()
{
    NSMutableSet *_translationsUnits;
    NSMutableArray *_files;
    NSArray *_ignore;
}

@end

@implementation JCDataLoader

-(instancetype)initWithFilePath:(NSString *)filePath ignore:(NSArray *)ignore;
{
    if (self = [super init]) {
        _ignore = ignore;
        _files = [NSMutableArray new];
        _translationsUnits = [NSMutableSet new];
        
        NSString *xmlString = [self loadResource:filePath];
        NSDictionary *data = [NSDictionary dictionaryWithXMLString:xmlString];
        
        NSArray *filesData = [data objectForKey:@"file"];
        for (NSDictionary *fileData in filesData) {
            JCFile *file = [[JCFile alloc] initWithDictionary:fileData];
            [_files addObject:file];
            [_translationsUnits addObjectsFromArray:file.translationUnits];
        }
    }
    return self;
}

-(NSString *)strings
{
    NSMutableArray *translationStrings = [NSMutableArray new];
    for (JCTranslationUnit *translationUnit in _translationsUnits) {
        JCTranslationString *translationString = [[JCTranslationString alloc] initWithSource:translationUnit.source
                                                                           target:translationUnit.target
                                                                             note:translationUnit.note];
        if (![translationStrings containsObject:translationString]) {
            [translationStrings addObject:translationString];
        } else {
            
        }
    }
    
    [translationStrings sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"source" ascending:YES]]];
    
    NSMutableString *output = [NSMutableString new];
    for (JCTranslationString *translationString in translationStrings) {
        if (![_ignore containsObject:translationString.source]) {
            [output appendString:[translationString description]];
        }
    }
    return output;
}

-(NSString *)loadResource:(NSString *)resource
{
    @autoreleasepool {
        __autoreleasing NSError *error = nil;
        NSURL *filePath = [NSURL fileURLWithPath:resource];
        NSString *dataString = [NSString stringWithContentsOfURL:filePath encoding:NSUTF8StringEncoding error:&error];
        return dataString;
    }
}

@end
