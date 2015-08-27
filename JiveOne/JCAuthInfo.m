//
//  JCAuthInfo.m
//  Pods
//
//  Created by Robert Barclay on 8/5/15.
//
//

#import "JCAuthInfo.h"

NSString *const kJCAuthInfoAccessTokenKey                   = @"access_token";
NSString *const kJCAuthInfoUsernameKey                      = @"username";
NSString *const kJCAuthInfoExpirationTimeIntervalKey        = @"expires_in";

NSString *const kJCAuthInfoAuthenticationDateKey            = @"authentication";
NSString *const kJCAuthInfoExpirationDateKey                = @"expiration";

@implementation JCAuthInfo

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
        _username = [tokenData valueForKey:kJCAuthInfoUsernameKey];
        if (!_username || _username.length == 0) {
            [NSException raise:NSInvalidArgumentException format:@"Username null or empty"];
        }
        
        // Retrive the access token
        _accessToken = [tokenData valueForKey:kJCAuthInfoAccessTokenKey];
        if (!_accessToken || _accessToken.length == 0) {
            [NSException raise:NSInvalidArgumentException format:@"Access Token null or empty"];
        }
        
        // Retrive the Expiration date.
        NSTimeInterval expirationTimeInterval = [self doubleValueFromDictionary:tokenData forKey:kJCAuthInfoExpirationTimeIntervalKey];
        if (expirationTimeInterval <= 0) {
            [NSException raise:NSInvalidArgumentException format:@"Expiration of token not found"];
        }
        
        // convert response from miliseconds to give us a date for expriation date that works with a
        // NSDate object, which functions in seconds.
        _expirationDate = [NSDate dateWithTimeIntervalSinceNow:expirationTimeInterval/1000];
        
        _authenticationDate = [NSDate new];
    }
    return self;
}

-(instancetype)initWithData:(NSData *)data
{
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [self initWithDictionary:(NSDictionary *)object];
}

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        _username           = [dictionary valueForKey:kJCAuthInfoUsernameKey];
        _accessToken        = [dictionary valueForKey:kJCAuthInfoAccessTokenKey];
        
        id expiration = [dictionary objectForKey:kJCAuthInfoExpirationDateKey];
        if ([expiration isKindOfClass:[NSNumber class]]) {
            _expirationDate = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)expiration).doubleValue];
        }
        
        id authentication = [dictionary objectForKey:kJCAuthInfoAuthenticationDateKey];
        if ([authentication isKindOfClass:[NSNumber class]]) {
            _authenticationDate = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)authentication).doubleValue];
        }
    }
    return self;
}

-(NSDictionary *)authToken
{
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary setValue:_username forKey:kJCAuthInfoUsernameKey];
    [dictionary setValue:_accessToken forKey:kJCAuthInfoAccessTokenKey];
    
    if (_expirationDate) {
        [dictionary setValue:[NSNumber numberWithDouble:[_expirationDate timeIntervalSince1970]] forKey:kJCAuthInfoExpirationDateKey];
    }
    if (_authenticationDate) {
        [dictionary setValue:[NSNumber numberWithDouble:[_authenticationDate timeIntervalSince1970]] forKey:kJCAuthInfoAuthenticationDateKey];
    }
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

-(NSData *)data
{
    return [NSKeyedArchiver archivedDataWithRootObject:self.authToken];
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
