//
//  JCDataLoader.h
//  JiveOne
//
//  Created by Robert Barclay on 6/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCDataLoader : NSObject

-(instancetype)initWithFilePath:(NSString *)filePath ignore:(NSArray *)ignore;

@property (nonatomic, readonly) NSArray *translationUnits;

@property (nonatomic, readonly) NSString *strings;

@end
