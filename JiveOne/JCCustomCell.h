//
//  JCCustomCell.h
//  JiveOne
//
//  Created by Robert Barclay on 1/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCTableViewCell.h"

@interface JCCustomCell : JCTableViewCell

@property (nonatomic, weak) IBOutlet UILabel *textLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailTextLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end
