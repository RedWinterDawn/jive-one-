//
//  JCTranslationString.h
//  JiveOne
//
//  Created by Robert Barclay on 6/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCTranslationString : NSObject

-(instancetype) initWithSource:(NSString *)source target:(NSString *)target note:(NSString *)note;

@property (nonatomic, readonly) NSString *source;
@property (nonatomic, strong) NSString *target;
@property (nonatomic, strong) NSString *note;

-(void)addTranslationString:(JCTranslationString *)translationString;

@end
