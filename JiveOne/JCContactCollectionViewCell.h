//
//  JCContactCollectionViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 3/30/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCContactCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *number;

@end
