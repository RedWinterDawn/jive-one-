//
//  JCContactCollectionViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 3/30/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCPhoneNumberCollectionViewCell : UICollectionViewCell

/**
 *  Returns the `UINib` object initialized for the cell.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during
 *  initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 *  Returns the default string used to identify a reusable cell for text message items.
 *
 *  @return The string used to identify a reusable cell.
 */
+ (NSString *)cellReuseIdentifier;

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *number;

@end
