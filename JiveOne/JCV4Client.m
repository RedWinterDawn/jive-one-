	//
//  JCV4ProvisioningClient.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCV4Client.h"

// Managed Objects
#import "LineConfiguration.h"
#import "Line.h"
#import "PBX.h"
#import "User.h"

NSString *const kJCV4ClientBaseUrl = @"https://pbx.onjive.com";

@implementation JCV4Client

-(instancetype)init
{
    return [self initWithBaseURL:[NSURL URLWithString:kJCV4ClientBaseUrl]];
}

-(instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        _manager.requestSerializer = [JCAuthenticationXmlRequestSerializer serializer];
        _manager.responseSerializer = [JCXMLParserResponseSerializer serializer];
    }
    return self;
}

@end

#pragma mark - JCV4ProvisioningRequest -

NSString *const kJCV4ProvisioningClientRequestString = @"<login user=\"%@\" password=\"%@\" token=\"%@\" pbxid=\"%@\" line=\"%@\" man=\"Apple\" device=\"%@\" os=\"%@\" loc=\"%@\" lang=\"%@\" uuid=\"%@\" spid=\"cpc\" build=\"%@\" type=\"%@\" />";

@implementation JCV4ProvisioningRequest

+(NSData *)postDataForLine:(Line *)line
{
    JCV4ProvisioningRequest *request = [[JCV4ProvisioningRequest alloc] initWithUserName:line.pbx.user.jiveUserId
                                                                                password:nil
                                                                                   token:[JCAuthenticationManager sharedInstance].authToken
                                                                                   pbxId:line.pbx.pbxId
                                                                               extension:line.extension];
    return request.postData;
}

-(instancetype)initWithUserName:(NSString *)userName password:(NSString *)password token:(NSString *)token pbxId:(NSString *)pbxId extension:(NSString *)extension
{
    self = [self init];
    if (self) {
        
        if (!userName) {
            [NSException raise:NSInvalidArgumentException format:@"User is NULL"];
        }
        _userName = userName;
        
        if (!token) {
            [NSException raise:NSInvalidArgumentException format:@"Token is NULL"];
        }
        _token = token;
        
        if (!pbxId) {
            [NSException raise:NSInvalidArgumentException format:@"PBX is NULL"];
        }
        _pbxId = pbxId;
        
        if (!extension) {
            [NSException raise:NSInvalidArgumentException format:@"Extension is NULL"];
        }
        _extension = extension;
        _password = password ? password : @"";
    }
    return self;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        NSBundle *bundle = [NSBundle mainBundle];
        NSLocale *local = [NSLocale currentLocale];
        UIDevice *device = [UIDevice currentDevice];
        
        _language          = [[bundle preferredLocalizations] objectAtIndex:0];
        _locale            = local.localeIdentifier;
        _appBuildString    = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        _model             = device.model;
        _os                = device.systemVersion;
        _uuid              = device.identifierForVendor.UUIDString;
        _type              = device.userInterfaceIdiom == UIUserInterfaceIdiomPhone ? @"ios.jive.phone" : @"ios.jive.tablet";
    }
    return self;
}

-(NSString *)xml
{
    return  [NSString stringWithFormat:kJCV4ProvisioningClientRequestString,
             _userName,
             _password,
             _token,
             _pbxId,
             _extension,
             _model,
             _os,
             _locale,
             _language,
             _uuid,
             _appBuildString,
             _type
             ];
}

-(NSData *)postData
{
    return [self.xml dataUsingEncoding:NSUTF8StringEncoding];
}

@end

#pragma mark - JCV4ProvisioningURLRequest -

@implementation JCV4ProvisioningURLRequest

+(NSMutableURLRequest *)requestWithLine:(Line *)line
{
    // Create the request
    NSURL *url = [NSURL URLWithString:kJCV4ProvisioningClientRequestUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    // Create Payload
    NSData *data = [JCV4ProvisioningRequest postDataForLine:line];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
    //[request setValue:[JCAuthenticationManager sharedInstance].authToken forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:data];
    return request;
}

@end
