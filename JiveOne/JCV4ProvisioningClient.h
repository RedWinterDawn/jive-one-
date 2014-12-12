//
//  JCV4ProvisioningClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Line;

@interface JCV4ProvisioningURLRequest : NSMutableURLRequest

+(NSMutableURLRequest *)requestWithLine:(Line *)line;

@end

@interface JCV4ProvisioningRequest : NSObject

-(instancetype)initWithUserName:(NSString *)userName password:(NSString *)password token:(NSString *)token pbxId:(NSString *)pbxId extension:(NSString *)extension;

@property (nonatomic, readonly) NSString *userName;
@property (nonatomic, readonly) NSString *password;
@property (nonatomic, readonly) NSString *token;
@property (nonatomic, readonly) NSString *pbxId;
@property (nonatomic, readonly) NSString *extension;
@property (nonatomic, readonly) NSString *language;
@property (nonatomic, readonly) NSString *locale;
@property (nonatomic, readonly) NSString *appBuildString;
@property (nonatomic, readonly) NSString *model;
@property (nonatomic, readonly) NSString *os;
@property (nonatomic, readonly) NSString *uuid;
@property (nonatomic, readonly) NSString *type;

@property (nonatomic, readonly) NSString *xml;
@property (nonatomic, readonly) NSData *postData;

@end

@interface JCV4ProvisioningClient : NSObject

+(void)requestProvisioningForLine:(Line *)line completed:(void (^)(BOOL suceeded, NSError *error))completed;

@end

typedef enum : NSUInteger {
    JCV4ProvisioningUnknownProvisioningError = 0,
    JCV4ProvisioningInvalidRequestParametersError,
    JCV4ProvisioningRequestResponseError,
    JCV4ProvisioningResponseParseError
} JCV4ProvisioningErrorType;

@interface JCV4ProvisioningError : NSError

+(instancetype)errorWithType:(JCV4ProvisioningErrorType)type reason:(NSString *)reason;

@end