//
//  SlopeData.m
//  SlopeFinder
//
//  Created by Vlad Turchenko on 7/13/16.
//  Copyright © 2016 Vlad Turchenko. All rights reserved.
//

#import "SlopeData.h"
#import <CoreGraphics/CoreGraphics.h>
#import <Math.h>
#import <UIKit/UIKit.h>
@import CoreMotion;

@interface SlopeData()

@property (nonatomic) CMMotionManager *motionManager;
@property CMAcceleration curGravity;
@end

@implementation SlopeData
//---------------------------------------------
static SlopeData *sharedInstance;
//---------------------------------------------------------------
+ (SlopeData *)sharedInstance
{
	@synchronized(self)
	{
		if (!sharedInstance)
			sharedInstance=[[SlopeData alloc] init];
	}
	return sharedInstance;
}
//---------------------------------------------------------------
+(id)alloc
{
	@synchronized(self)
	{
		NSAssert(sharedInstance == nil, @"Attempted to allocate a second instance of a singleton SlopeData.");
		sharedInstance = [super alloc];
	}
	return sharedInstance;
}
//---------------------------------------------------------------
- (void)dealloc
{
	[self goBackground];
}
//---------------------------------------------------------------
-(void) goBackground
{
	[self.motionManager stopDeviceMotionUpdates];
}
//---------------------------------------------------------------
-(void) goForeground
{
	{
		[self.motionManager startDeviceMotionUpdatesToQueue:NSOperationQueue.mainQueue
												withHandler:^ (CMDeviceMotion *motion, NSError *error) {
													if (error) {
														NSLog(@"Device motion error: %@", error);
														return;
													}
													self.curGravity = motion.gravity;
													[self processData];
												}];
	}
}
//---------------------------------------------------------------
-(id) init
{
	if (self = [super init])
	{
		self.motionManager = [[CMMotionManager alloc] init];
		self.motionManager.deviceMotionUpdateInterval = 1.0 / 30.0;
	}
	return self;
}
//---------------------------------------------------------------
-(void) start
{
	[self goForeground];
}
//---------------------------------------------------------------
-(void) stop
{
	[self goBackground];
}
//---------------------------------------------
- (void) processData
{
	// normalize the XY components
	double length = sqrt(self.curGravity.x * self.curGravity.x + self.curGravity.y * self.curGravity.y + self.curGravity.z * self.curGravity.z);
	CGPoint normalizedXY = CGPointMake(-self.curGravity.x / length, self.curGravity.y / length);
	double length2 = sqrt(normalizedXY.x * normalizedXY.x + normalizedXY.y * normalizedXY.y);
	self.slopeAngle = 0.0f;
	self.slopeAngleDisplay = 0.0f;
	if( length2 > 0.001 )
	{
		// all this needed to handle changing phone orientation
		// maybe there is easier way, don't have time to explore right now
		// todo...
		self.slopeAngle = atan2(normalizedXY.x, normalizedXY.y) + M_PI * 0.5;
		self.slopeAngle *= 180.0 / M_PI;

		self.slopeAngleDisplay = self.slopeAngle;
		if( self.slopeAngleDisplay > 90.0 )
			self.slopeAngleDisplay -= 180.0;
		if( self.slopeAngle > 180.0f )
			self.slopeAngle -= 360.0;
		UIInterfaceOrientation orient = [[UIApplication sharedApplication] statusBarOrientation];
		switch( orient )
		{
			case UIDeviceOrientationLandscapeRight:
				break;
			case UIDeviceOrientationLandscapeLeft:
				self.slopeAngle = self.slopeAngle;
				if( self.slopeAngle < 0.0f )
					self.slopeAngle += 180.0;
				else if( self.slopeAngle > 0.0f )
					self.slopeAngle -= 180.0;
				break;
			default:
				break;
		}
	}
}
//---------------------------------------------
//---------------------------------------------
@end
