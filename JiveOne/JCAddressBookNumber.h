//
//  JCAddressBookNumber.h
//  JiveOne
//
//  Created by Robert Barclay on 2/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JCPersonDataSource.h"
#import <UIKit/UIKit.h>

@interface JCAddressBookNumber : NSObject <JCPersonDataSource>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *number;
@property (nonatomic, strong) NSString *type;

@end
