//
//  JCStaticRowData.h
//  JiveOne
//
//  Created by Robert Barclay on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@interface JCStaticRowData : NSObject

@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic) UITableViewCell *cell;

@end
