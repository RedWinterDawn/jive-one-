//
//  JCContactModel.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/18/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "MBContactModel.h"
#import "ClientEntities.h"

@interface JCContactModel : MBContactModel

@property (nonatomic)ClientEntities *person;

@end
