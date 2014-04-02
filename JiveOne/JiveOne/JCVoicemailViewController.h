//
//  JCVoicemailViewController.h
//  JiveOne
//
//  Created by Doug Leonard on 2/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCVoicemailCell.h"
#import "JCOsgiClient.h"

@interface JCVoicemailViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray* voicemails; //of type voicemail(entity). Exposed for testing

- (void)tableView:(UITableView*)tableView;
- (void)updateVoicemailData;
- (void)reloadcell:(JCVoicemailCell *)cell;
- (NSData*)getVoiceMailDataUsingString: (NSString*)String;
-(void)voiceCellDeleteTapped:(JCVoicemailCell *)cell;//exposed for testing
@property (nonatomic,strong) JCVoicemailCell *currentVoicemailCell;

- (void)osgiClient:(JCOsgiClient*)client;
@end
