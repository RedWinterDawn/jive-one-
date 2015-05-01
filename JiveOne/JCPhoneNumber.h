//
//  JCNumber.h
//  JiveOne
//
//  Created by Robert Barclay on 4/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberDataSource.h"
#import <libPhoneNumber-iOS/NBPhoneNumber.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>

@interface JCPhoneNumber : NSObject <JCPhoneNumberDataSource>

+(NBPhoneNumberUtil *)phoneNumberUtilities;

+(instancetype)phoneNumberWithName:(NSString *)name number:(NSString *)number;

-(instancetype)initWithName:(NSString *)name number:(NSString *)number;

@property (nonatomic, strong) NSString *number;
@property (nonatomic, strong, readwrite) NSString *name;

@property (nonatomic, strong) NSString *extension;
@property (nonatomic, strong) NSNumber *countryCode;
@property (nonatomic, strong) NSNumber *nationalNumber;
@property (nonatomic, strong) NSNumber *countryCodeSource;
@property (nonatomic, strong) NSString *preferredDomesticCarrierCode;

@property (nonatomic) BOOL italianLeadingZero;

@end