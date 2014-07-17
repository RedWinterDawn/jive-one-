//
//  JCVoicemailClient.h
//  JiveOne
//
//  Created by Daniel George on 6/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCVoicemailClient : NSObject

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

+ (instancetype)sharedClient;
- (void)getVoicemails :(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
- (void)downloadVoicemailEntry:(Voicemail*)voicemail completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
- (void)updateVoicemailToRead:(Voicemail*)voicemail completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
- (void)deleteVoicemail:(NSString *)url completed:(void (^)(BOOL succeeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
@end
