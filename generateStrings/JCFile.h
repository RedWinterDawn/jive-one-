//
//  JCFile.h
//  JiveOne
//
//  Created by Robert Barclay on 6/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCFile : NSObject

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSString *dataType;
@property (nonatomic, readonly) NSString *original;
@property (nonatomic, readonly) NSString *sourceLanguage;
@property (nonatomic, readonly) NSString *targetLanguage;

@property (nonatomic, readonly) NSArray *translationUnits;

@end
