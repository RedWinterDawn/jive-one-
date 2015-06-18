//
//  JCDataLoader.m
//  JiveOne
//
//  Created by Robert Barclay on 6/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCDataLoader.h"

NSString *const kDataFilePath = @"inputs/";

NSString *const kDataGermanFile = @"de";

NSString *const kDataFileExtension = @"xliff";

@interface JCDataLoader ()
{
    
}

@end


@implementation JCDataLoader

-(instancetype)initWithFilePath:(NSString *)filePath
{
    if (self = [super init]) {
        NSString *fileData = [self loadResource:filePath];
        NSLog(@"%@", fileData);
    }
    return self;
}



-(NSString *)loadResource:(NSString *)resource
{
    @autoreleasepool {
        __autoreleasing NSError *error = nil;
        
        NSURL *path = [self applicationDataDirectory];
        
        NSLog(@"%@", path);
        
        NSString *csvString = [NSString stringWithContentsOfFile:path.absoluteString encoding:NSUTF8StringEncoding error:&error];
        
        NSLog(@"%@", error);
        
        return csvString;
    }
}

- (NSURL*)applicationDataDirectory {
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSArray* possibleURLs = [sharedFM URLsForDirectory:NSApplicationSupportDirectory
                                             inDomains:NSUserDomainMask];
    NSURL* appSupportDir = nil;
    NSURL* appDirectory = nil;
    
    if ([possibleURLs count] >= 1) {
        // Use the first directory (if multiple are returned)
        appSupportDir = [possibleURLs objectAtIndex:0];
    }
    
    // If a valid app support directory exists, add the
    // app's bundle ID to it to specify the final directory.
    if (appSupportDir) {
        NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
        if(appBundleID)
            appDirectory = [appSupportDir URLByAppendingPathComponent:appBundleID];
    }
    
    return appDirectory;
}


@end
