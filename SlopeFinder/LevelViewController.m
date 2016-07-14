//
//  LevelViewController.m
//  SlopeFinder
//
//  Created by Vlad Turchenko on 7/13/16.
//  Copyright © 2016 Vlad Turchenko. All rights reserved.
//

#import "LevelViewController.h"
#import "SlopeData.h"
#import "AppDelegate.h"

@interface LevelViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelAngle;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, weak) SlopeData *slopeData;

@property BOOL directionAnimating;
@end

@implementation LevelViewController
//---------------------------------------------
- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	self.slopeData = appDelegate.slopeData;
	self.directionAnimating = NO;
}
//---------------------------------------------
- (void) viewDidAppear:(BOOL)animated
{
	[self.slopeData start];
	self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(refreshData) userInfo:nil repeats:YES];
}
//---------------------------------------------
- (void) viewWillDisappear:(BOOL)animated
{
	[self.timer invalidate], self.timer = nil;
	[self.slopeData stop];
}
//---------------------------------------------
- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}
//---------------------------------------------
- (void)refreshData
{
	double angle = self.slopeData.slopeAngle;
	double angleDisplay = self.slopeData.slopeAngleDisplay;
	self.labelAngle.text = [NSString stringWithFormat:@"_____%.1f_____", fabs(angleDisplay)];
	[self setDirection:angle];
}
//---------------------------------------------
//---------------------------------------------------------------
- (void) setDirection:(double)valueDirection
{
	if( self.directionAnimating )
		return;
	[self.labelAngle.layer removeAllAnimations];
	self.directionAnimating = YES;
	[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear
					 animations:^{
						 self.labelAngle.transform = CGAffineTransformMakeRotation(-valueDirection / 180.0 * M_PI);
					 }
					 completion:^(BOOL finished){
						 self.directionAnimating = NO;
					 }];
	
}
//---------------------------------------------
//---------------------------------------------
@end
