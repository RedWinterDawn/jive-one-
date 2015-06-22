//
//  JCTableViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 10/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCTableViewCell : UITableViewCell

@property (nonatomic, strong) UIColor *seperatorColor;
@property (nonatomic) BOOL top;
@property (nonatomic) BOOL bottom;
@property (nonatomic) BOOL lastRow;
@property (nonatomic) BOOL lastRowOnly;

@end
