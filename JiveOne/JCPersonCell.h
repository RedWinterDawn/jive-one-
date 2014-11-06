//
//  JCPersonCell.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

#import "JCPresenceView.h"
#import "Lines+Custom.h"

@interface JCPersonCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *personNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *personDetailLabel;
@property (nonatomic, weak) IBOutlet UIButton *favoriteBut;
@property (nonatomic, weak) IBOutlet JCPresenceView *personPresenceView;

@property (nonatomic) Lines *line;

- (IBAction)toggleFavoriteStatus:(id)sender;

@end

