//
//  JCLineSelectorViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLineSelectorViewController.h"
#import "JCTableViewCellWithInset.h"

@interface JCLineSelectorViewController ()

@property (strong, nonatomic) NSArray *pbxList;
@property (strong, nonatomic) NSArray *lineList;

@end

@implementation JCLineSelectorViewController

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    _bluredBackgroundImage = backgroundImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self setupView];
	[self loadLists];
    
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
    
    
    self.view.backgroundColor = [UIColor clearColor];
    UIImageView *backView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backView.image = _bluredBackgroundImage;
    backView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    self.tableView.backgroundView = backView;
	
	
}

- (void)loadLists
{
	_pbxList = [PBX MR_findAllSortedBy:@"name" ascending:YES];
	_lineList = [Lines MR_findByAttribute:@"userName" withValue:@"egueiros"];
//	for (PBX *pbx in _pbxList) {
//		NSArray *lines = [Lines MR_findByAttribute:@"pbxId" withValue:pbx.pbxId andOrderBy:@"displayName" ascending:YES];
//		[_lineList setObject:lines forKey:pbx.name];
//	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//	NSString *key = self.lineList.allKeys[section];
//	return ((NSArray *) self.lineList[key]).count;
	if (section == 0) {
		return self.lineList.count;
	}
	
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JCTableViewCellWithInset *cell = [tableView dequeueReusableCellWithIdentifier:@"LineCell"];
    if (indexPath.section == 0 && indexPath.row == 0) {
        CAShapeLayer *shape = [[CAShapeLayer alloc] init];
        shape.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height) byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(10, 10)].CGPath;
        cell.layer.mask = shape;
        cell.layer.masksToBounds = YES;
    }
    else if (indexPath.section == 0 && indexPath.row == (self.lineList.count - 1)) {
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
	
	if (indexPath.section != 1) {
		Lines *line = self.lineList[indexPath.row];
		cell.textLabel.text = [NSString stringWithFormat:@"%@/%@", line.externsionNumber, line.displayName];
		cell.textLabel.textColor = [UIColor lightGrayColor];
		cell.detailTextLabel.textColor = [UIColor lightGrayColor];
	}
	else {
		cell.textLabel.text = @"Cancel";
		cell.textLabel.center = cell.center;
		cell.backgroundColor = [UIColor whiteColor];
	}
    
	cell.detailTextLabel.hidden = YES;
    return cell;
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"index:section:%ld", (long)indexPath.section);
    NSLog(@"index:section:%ld", (long)indexPath.row);
    if (indexPath.section == 0) {
        [self changeLine:indexPath.row];
    }
    if (indexPath.section == 1 && indexPath.row == 0) {
        [self dismissView];
    }
}

- (void)changeLine:(NSInteger)row
{
	Lines *line = self.lineList[row];
	
	if (line &&_delegate && [_delegate respondsToSelector:@selector(didChangeLine:)]) {
		[_delegate didChangeLine:line];
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

@end
