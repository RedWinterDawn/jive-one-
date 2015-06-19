//
//  JCTranslationUnit.h
//  JiveOne
//
//  Created by Robert Barclay on 6/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCTranslationUnit : NSObject

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *source;
@property (nonatomic, strong) NSString *target;
@property (nonatomic, readonly) NSString *note;

@end
