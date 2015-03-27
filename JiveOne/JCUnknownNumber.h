//
//  JCMessageParticipant.h
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JCPersonDataSource.h"

@interface JCUnknownNumber :  NSObject <JCPersonDataSource>

+(instancetype) unknownNumberWithNumber:(NSString *)number;

@property (nonatomic, strong) NSString *number;

@end
