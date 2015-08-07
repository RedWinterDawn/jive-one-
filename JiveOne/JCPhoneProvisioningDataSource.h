//
//  JCSipManagerDataSource.h
//  JiveOne
//
//  Created by Robert Barclay on 4/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@protocol JCPhoneProvisioningDataSource <NSObject>

@property (nonatomic, readonly) BOOL isProvisioned;
@property (nonatomic, readonly) BOOL isV5;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *password;
@property (nonatomic, readonly) NSString *outboundProxy;
@property (nonatomic, readonly) NSString *registrationHost;
@property (nonatomic, readonly) NSString *server;

-(void)refreshProvisioningProfileWithCompletion:(void(^)(BOOL success, NSError *error))completion;

@end

