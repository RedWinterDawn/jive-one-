//
//  JCPresenceViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/4/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPresenceViewController.h"
#import "JCPresenceView.h"

@interface JCPresenceViewController ()
@property (weak, nonatomic) IBOutlet JCPresenceView *presenceAvailable;
@property (weak, nonatomic) IBOutlet JCPresenceView *presenceBusy;
@property (weak, nonatomic) IBOutlet JCPresenceView *presenceDisturb;
@property (weak, nonatomic) IBOutlet JCPresenceView *presenceOffline;

@end

@implementation JCPresenceViewController

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    _bluredBackgroundImage = backgroundImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupView];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            [self.tableView setContentInset:UIEdgeInsetsMake(240, 0, 0, 0)];
        } completion:^(BOOL finished) {
            //completed.
        }];
    });
}

- (void)setupView
{
    
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    [self.tableView setContentInset:UIEdgeInsetsMake(self.view.frame.size.height, 0, 0, 0)];
    
    _presenceAvailable.presenceType = JCPresenceTypeAvailable;
    _presenceBusy.presenceType = JCPresenceTypeBusy;
    _presenceDisturb.presenceType = JCPresenceTypeDoNotDisturb;
    _presenceOffline.presenceType = JCPresenceTypeOffline;
    
//    CGRect currentFrame = self.tableView.frame;
//    CGRect zeroFrame = currentFrame;
//    zeroFrame.origin.x = self.view.frame.size.height;
//    self.tableView.frame = zeroFrame;
    
    self.view.backgroundColor = [UIColor clearColor];
    UIImageView *backView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backView.image = _bluredBackgroundImage;
    backView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    self.tableView.backgroundView = backView;


}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 4;
    }
    
    return 1;
}


/*- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JCTableViewCellWithInset *cell = (JCTableViewCellWithInset *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0 && indexPath.row == 0) {
        CAShapeLayer *shape = [[CAShapeLayer alloc] init];
        shape.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height) byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(10, 10)].CGPath;
        cell.layer.mask = shape;
        cell.layer.masksToBounds = YES;
    }
    else if (indexPath.section == 0 && indexPath.row == 3) {
        CAShapeLayer *shape = [[CAShapeLayer alloc] init];
        shape.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height) byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight cornerRadii:CGSizeMake(10, 10)].CGPath;
        cell.layer.mask = shape;
        cell.layer.masksToBounds = YES;
    }
    else if (indexPath.section == 1)
    {
        cell.layer.cornerRadius = 10;
        cell.layer.masksToBounds = YES;
    }
    
    
    return cell;

}*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    NSLog(@"index:section:%ld", (long)indexPath.section);
    NSLog(@"index:section:%ld", (long)indexPath.row);
    if (indexPath.section == 0) {
        [self changedPresence:indexPath.row];
    }
    if (indexPath.section == 1 && indexPath.row == 0) {
        [self dismissView];
    }
}

- (void)changedPresence:(NSInteger)row
{
    JCPresenceType type;
    switch (row) {
        case 0:
            //state = kPresenceAvailable;
            type = JCPresenceTypeAvailable;
            break;
        case 1:
            //state = kPresenceBusy;
            type = JCPresenceTypeBusy;
            break;
        case 2:
            //state = kPresenceDoNotDisturb;
            type = JCPresenceTypeDoNotDisturb;
            break;
        case 3:
            //state = kPresenceInvisible;
            type = JCPresenceTypeOffline;
            break;
        default:
            //state = self.presenceDetail.text;
            type = JCPresenceTypeNone;
    }
    
    if  (_delegate && [_delegate respondsToSelector:@selector(didChangePresence:)]) {
        [_delegate didChangePresence:type];
    }
    
    [self dismissView];
}

- (void)dismissView
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{

            [self.tableView setContentInset:UIEdgeInsetsMake(700, 0, -700, 0)];
            
        } completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    });

}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
