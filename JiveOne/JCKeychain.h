//
//  JCKeychain.h
//  JiveOne
//
//  Created by Robert Barclay on 12/22/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@interface JCKeychain : NSObject

+ (NSMutableDictionary *)getKeychainQuery:(NSString *)key;
+ (BOOL)saveValue:(id)value forKey:(NSString *)key;
+ (BOOL)deleteValueForKey:(NSString *)key;
+ (id)loadValueForKey:(NSString *)key;

@end
