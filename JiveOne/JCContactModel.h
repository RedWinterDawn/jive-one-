//
//  JCContactModel.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/18/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "MBContactModel.h"
#import "PersonEntities.h"

@interface JCContactModel : MBContactModel

@property (nonatomic)PersonEntities *person;

@end
