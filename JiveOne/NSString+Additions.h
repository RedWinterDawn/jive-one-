//
//  NSString+Custom.h
//  JiveOne
//
//  Created by Robert Barclay on 11/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Validations)

-(BOOL)isEmpty;

@end

@interface NSString (MD5Additions)

- (NSString *)MD5Hash;

@end