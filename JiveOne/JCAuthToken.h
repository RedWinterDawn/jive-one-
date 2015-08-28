//
//  JCAuthInfo.h
//  Pods
//
//  Created by Robert Barclay on 8/5/15.
//
//

@import Foundation;

extern NSString *const kJCAuthTokenAccessTokenKey;
extern NSString *const kJCAuthTokenUsernameKey;
extern NSString *const kJCAuthTokenExpirationTimeIntervalKey;
extern NSString *const kJCAuthTokenAuthenticationDateKey;
extern NSString *const kJCAuthTokenExpirationDateKey;

@interface JCAuthToken : NSObject <NSCoding>

-(instancetype)initWithUrl:(NSURL *)url;

@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) NSDate *expirationDate;
@property (nonatomic, readonly) NSDate *authenticationDate;

@end
