//
//  NSString+URLEncoding.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 5/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URLEncoding)

/*!
 *
 * Encodes the string for use in a URL.
 *
 * @returns The string encoded for use in a URL
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
 **/
- (NSString *)URLEncodedString;

/*!
 *
 * Decodes the string if it was encoded for us in a URL.
 *
 * @returns The decoded string
 *
 * @available Available in Singly iOS SDK 1.1.0 and later.
 *
 **/
- (NSString *)URLDecodedString;

@end
