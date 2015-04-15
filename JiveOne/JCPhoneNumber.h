//
//  JCNumber.h
//  JiveOne
//
//  Created by Robert Barclay on 4/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberDataSource.h"

@interface JCPhoneNumber : NSObject <JCPhoneNumberDataSource>

+(instancetype)phoneNumberWithName:(NSString *)name number:(NSString *)number;

-(instancetype)initWithName:(NSString *)name number:(NSString *)number;

@property (nonatomic, strong) NSString *number;
@property (nonatomic, strong) NSString *name;

@end