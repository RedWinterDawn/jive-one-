//
//  JCPhoneTypeSelectorTableController.h
//  JiveOne
//
//  Created by P Leonard on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JCTypeSelectorTableControllerDelegate;

@interface JCTypeSelectorViewController : UITableViewController

+(NSArray *)phoneTypes;
+(NSArray *)addressTypes;
+(NSArray *)otherTypes;

@property (nonatomic, weak) id<JCTypeSelectorTableControllerDelegate> delegate;

@property (nonatomic, strong) id sender;
@property (nonatomic, strong) NSArray *types;

@end


@protocol JCTypeSelectorTableControllerDelegate <NSObject>

-(void)typeSelectorController:(JCTypeSelectorViewController *)controller didSelectPhoneType:(NSString *)phoneType;

@end
