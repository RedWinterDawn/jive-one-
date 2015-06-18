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
        
        NSLog(@"%@", arguments);
        
        
        //        DebugLog(@"arguments: %@", arguments);
        
        //        DebugLog(@"environment: %@", [[NSProcessInfo processInfo] environment]);
        
//        if (arguments.count < 4 || (arguments.count >= 2 && [@"-?" isEqualToString:arguments[1]])) {
//            printf("%s <source path> <destination path> <prefix>\n", [[[NSProcessInfo processInfo] processName] UTF8String]);
//        }
//        else if (arguments.count >= 4) {
//            SnippetImporter *importer = [[SnippetImporter alloc] init];
//            [importer importSnippetsWithSourcePath:arguments[1] destinationPath:arguments[2] prefix:arguments[3]];
//        }
        
        
        
//        JCDataLoader *dataLoader = [[JCDataLoader alloc] initWithFilePath:@"input/de.xliff"];
        
        
        // insert code here...
        NSLog(@"Hello, World!");
    }
    return 0;
}

