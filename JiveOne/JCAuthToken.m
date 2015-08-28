//
//  JCAuthInfo.m
//  Pods
//
//  Created by Robert Barclay on 8/5/15.
//
//

#import "JCAuthToken.h"

NSString *const kJCAuthTokenAccessTokenKey                   = @"access_token";
NSString *const kJCAuthTokenUsernameKey                      = @"username";
NSString *const kJCAuthTokenExpirationTimeIntervalKey        = @"expires_in";
NSString *const kJCAuthTokenAuthenticationDateKey            = @"authentication";
NSString *const kJCAuthTokenExpirationDateKey                = @"expiration";

@implementation JCAuthToken

-(instancetype)initWithUrl:(NSURL *)url
{
    self = [super init];
    if (self) {
        NSDictionary *tokenData = [self tokenDataFromURL:url];
        
        if (!tokenData || tokenData.count < 1) {
            [NSException raise:NSInvalidArgumentException format:@"Token Data is NULL"];
        }
        
        if (tokenData[@"error"]) {
            [NSException raise:NSInvalidArgumentException format:@"%@", tokenData[@"error"]];
        }
        
        // Validate Jive User ID. Get the responce user ID, which should match the username we requested.
        _username = [tokenData valueForKey:kJCAuthTokenUsernameKey];
        if (!_username || _username.length == 0) {
            [NSException raise:NSInvalidArgumentException format:@"Username null or empty"];
        }
        
        // Retrive the access token
        _accessToken = [tokenData valueForKey:kJCAuthTokenAccessTokenKey];
        if (!_accessToken || _accessToken.length == 0) {
            [NSException raise:NSInvalidArgumentException format:@"Access Token null or empty"];
        }
        
        // Retrive the Expiration date.
        NSTimeInterval interval = [self doubleValueFromDictionary:tokenData forKey:kJCAuthTokenExpirationTimeIntervalKey];
        if (interval <= 0) {
            [NSException raise:NSInvalidArgumentException format:@"Expiration of token not found"];
        }
        
        // convert response from miliseconds to give us a date for expriation date that works with a
        // NSDate object, which functions in seconds.
        _authenticationDate = [NSDate new];
        _expirationDate = [NSDate dateWithTimeInterval:interval/1000 sinceDate:_authenticationDate];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        _username = [decoder decodeObjectForKey:kJCAuthTokenUsernameKey];
        if (!_username || _username.length == 0) {
            [NSException raise:NSInvalidArgumentException format:@"Username null or empty"];
        }
        
        _accessToken = [decoder decodeObjectForKey:kJCAuthTokenAccessTokenKey];
        if (!_accessToken || _accessToken.length == 0) {
            [NSException raise:NSInvalidArgumentException format:@"Access Token null or empty"];
        }
        
        id expiration = [decoder decodeObjectForKey:kJCAuthTokenExpirationDateKey];
        if ([expiration isKindOfClass:[NSNumber class]]) {
            _expirationDate = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)expiration).doubleValue];
        }
        
        id authentication = [decoder decodeObjectForKey:kJCAuthTokenAuthenticationDateKey];
        if ([authentication isKindOfClass:[NSNumber class]]) {
            _authenticationDate = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)authentication).doubleValue];
        }
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_username forKey:kJCAuthTokenUsernameKey];
    [encoder encodeObject:_accessToken forKey:kJCAuthTokenAccessTokenKey];
    if (_expirationDate) {
        [encoder encodeObject:[NSNumber numberWithDouble:[_expirationDate timeIntervalSince1970]] forKey:kJCAuthTokenExpirationDateKey];
    }
    if (_authenticationDate) {
        [encoder encodeObject:[NSNumber numberWithDouble:[_authenticationDate timeIntervalSince1970]] forKey:kJCAuthTokenAuthenticationDateKey];
    }
}

#pragma mark - Private -

- (NSDictionary *)tokenDataFromURL:(NSURL *)url
{
    NSString *stringURL = [url description];
    NSArray *topLevel =  [stringURL componentsSeparatedByString:@"#"];
    NSArray *urlParams = [topLevel[1] componentsSeparatedByString:@"&"];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    for (NSString *param in urlParams)
    {
        NSArray *keyValue = [param componentsSeparatedByString:@"="];
        NSString *key = [keyValue objectAtIndex:0];
        NSString *value = [keyValue objectAtIndex:1];
        [data setObject:value forKey:key];
    }
    return data;
}

-(double)doubleValueFromDictionary:(NSDictionary *)dictionary forKey:(NSString *)key
{
    id object = [dictionary objectForKey:key];
    if ([object isKindOfClass:[NSNumber class]])
        return ((NSNumber *)object).floatValue;
    else if([object isKindOfClass:[NSString class]])
    {
        NSString *string = (NSString *)object;
        double value = string.doubleValue;
        return value;
    }
    return 0.0f;
}

@end
