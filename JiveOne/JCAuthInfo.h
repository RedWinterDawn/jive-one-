//
//  JCAuthInfo.h
//  Pods
//
//  Created by Robert Barclay on 8/5/15.
//
//

@import Foundation;

@interface JCAuthInfo : NSObject

-(instancetype)initWithUrl:(NSURL *)url;
-(instancetype)initWithData:(NSData *)data;
-(instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) NSString *refreshToken;
@property (nonatomic, readonly) NSDate *expirationDate;
@property (nonatomic, readonly) NSDate *authenticationDate;

@property (nonatomic, readonly) NSDictionary *authToken;
@property (nonatomic, readonly) NSData *data;

@end
