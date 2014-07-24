//
//  NSDictionary+QueryString.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 5/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (QueryString)

/*!
 *
 * Initializes a new dictionary containing the keys and values from the
 * specified query string.
 *
 * @param queryString The query parameters to parse
 *
 * @returns A new dictionary containing the specified query parameters.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
 **/
+ (NSDictionary *)dictionaryWithQueryString:(NSString *)queryString;

/*!
 *
 * Returns the dictionary as a query string.
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
 **/
- (NSString *)queryStringValue;

@end
