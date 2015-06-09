//
//  JCContactCell.h
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonCell.h"
#import "InternalExtension.h"

@protocol JCContactCellDelegate;

@interface JCContactCell : JCPresenceCell

@property (weak, nonatomic) id<JCContactCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *favoriteBtn;
@property (nonatomic, getter=isFavorite) BOOL favorite;

- (IBAction)toggleFavoriteStatus:(id)sender;

@end


@protocol JCContactCellDelegate <NSObject>

-(void)contactCell:(JCContactCell *)cell didMarkAsFavorite:(BOOL)favorite;

@end