//
//  JCPhoneTypeSelectorTableController.h
//  JiveOne
//
//  Created by P Leonard on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JCPhoneTypeSelectorTableControllerDelegate;

@interface JCPhoneTypeSelectorViewController : UITableViewController

@property (nonatomic, weak) id<JCPhoneTypeSelectorTableControllerDelegate> delegate;

@property (nonatomic, strong) id sender;

@end


@protocol JCPhoneTypeSelectorTableControllerDelegate <NSObject>

-(void)phoneTypeSelectorController:(JCPhoneTypeSelectorViewController *)controller didSelectPhoneType:(NSString *)phoneType;

@end
