//
//  JCMessageParticipant.h
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <JCPhoneModule/JCPhoneModule.h>

@interface JCUnknownNumber : JCPhoneNumber

+(instancetype) unknownNumberWithNumber:(NSString *)number;

@end
