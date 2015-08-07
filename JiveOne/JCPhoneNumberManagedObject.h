//
//  JCPhoneNumberManagedObject.h
//  JiveOne
//
//  Created by Robert Barclay on 4/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "JCPhoneNumberDataSource.h"

@interface JCPhoneNumberManagedObject : NSManagedObject <JCPhoneNumberDataSource>

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *number;
@property (nonatomic, strong) NSString *t9;

@property (nonatomic, strong) NSString *dialableNumber;

@property (nonatomic, readonly) NSString *firstInitial;

@end
