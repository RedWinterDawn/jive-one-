//
//  main.m
//  GenerateStrings
//
//  Created by Robert Barclay on 6/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JCDataLoader.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSArray *arguments = [[NSProcessInfo processInfo] arguments];
        
        NSString *basePath      = [arguments[0] stringByDeletingLastPathComponent];
        NSString *inputPath     = [NSString stringWithFormat:@"%@/%@", basePath, arguments[1]];
        NSString *outputPath    = [NSString stringWithFormat:@"%@/%@", basePath, arguments[2]];
        NSArray *files = [arguments[3] componentsSeparatedByString:@","];
        
        NSString *ignoreFile = arguments[4];
        
        __autoreleasing NSError *error;
        NSURL *ignoreFilePath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", inputPath, ignoreFile]];
        NSString *ignoreData = [NSString stringWithContentsOfURL:ignoreFilePath encoding:NSUTF8StringEncoding error:&error];
        NSArray *ignore = [ignoreData componentsSeparatedByString:@"\n"];
        
        for (NSString *fileName in files) {
            NSString *input = [NSString stringWithFormat:@"%@%@.xliff", inputPath, fileName];
            
            JCDataLoader *loader = [[JCDataLoader alloc] initWithFilePath:input ignore:ignore];
            
            NSString *strings = loader.strings;
            
            __autoreleasing NSError *error;
            NSString *output = [NSString stringWithFormat:@"%@%@.strings", outputPath, fileName];
            if (![strings writeToFile:output atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
                NSLog(@"%@", error);
            }
        }
    }
    return 0;
}

