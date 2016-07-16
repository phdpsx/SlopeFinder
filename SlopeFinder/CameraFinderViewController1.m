//
//  CameraFinderViewController.m
//  SlopeFinder
//
//  Created by Vlad Turchenko on 7/13/16.
//  Copyright © 2016 Vlad Turchenko. All rights reserved.
//
#import "CameraFinderViewController1.h"
#import <AVFoundation/AVFoundation.h>
#import "CameraPreviewView.h"
#import "SlopeData.h"
#import "AppDelegate.h"

@interface CameraFinderViewController ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, weak) SlopeData *slopeData;
@property BOOL directionAnimating;

@property (nonatomic, weak) IBOutlet CameraPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UILabel *labelAlignText;
@property (weak, nonatomic) IBOutlet UILabel *labelAlignLine;
@property (weak, nonatomic) IBOutlet UILabel *labelSlopeAngle;
@property (weak, nonatomic) IBOutlet UIView *viewSlopeAngle;

@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureDevice *videoDevice;

@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@property (nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@end

@implementation CameraFinderViewController
//---------------------------------------------
+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
	return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}
//---------------------------------------------
- (BOOL)isSessionRunningAndDeviceAuthorized
{
	return [[self session] isRunning] && [self isDeviceAuthorized];
}
//---------------------------------------------
- (BOOL)shouldAutorotate
{
	// Disable autorotation of the interface when recording is in progress.
	return ![self lockInterfaceRotation];
//	return NO;
}
//---------------------------------------------
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}
//---------------------------------------------
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	self.captureVideoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)toInterfaceOrientation;
}
//---------------------------------------------
- (void)viewDidLoad
{
	[super viewDidLoad];
	// initialize camera capture
	[self initCapture];
	// get motion controller to handle angle query
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	self.slopeData = appDelegate.slopeData;
	self.directionAnimating = NO;
}
//---------------------------------------------
- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}
//---------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
	[[self.captureVideoPreviewLayer connection] setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
	[self.session startRunning];
	// bring these views upfront, storyboard fails to do that
	[self.view bringSubviewToFront:self.labelAlignText];
	[self.view bringSubviewToFront:self.labelAlignLine];
	[self.view bringSubviewToFront:self.viewSlopeAngle];
	
//	[UIView setAnimationsEnabled:NO];
}
//---------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
	//start animation update timer and motion controller service
	[self.slopeData start];
	self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(refreshData) userInfo:nil repeats:YES];
//	NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
//	[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
//	[UIView setAnimationsEnabled:YES];
//	[UIViewController attemptRotationToDeviceOrientation];
}
//---------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
	//stop timers and services
	[self.session stopRunning];
	[self.timer invalidate], self.timer = nil;
	[self.slopeData stop];
}
//---------------------------------------------
- (void)refreshData
{
	double angle = self.slopeData.slopeAngle;
	double angleDisplay = self.slopeData.slopeAngleDisplay;
	self.labelSlopeAngle.text = [NSString stringWithFormat:@"_____%.1f_____", fabs(angleDisplay)];
	[self setDirection:angle];
}
//---------------------------------------------
- (void)initCapture
{
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	

	AVCaptureDevice *inputDevice = [CameraFinderViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];

	// Check for device authorization
	[self checkDeviceAuthorizationStatus];
	
//	AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
	if (!captureInput)
	{
		return;
	}
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	[captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

	NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
	NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
	[captureOutput setVideoSettings:videoSettings];

	// set up capture session
	self.session = [[AVCaptureSession alloc] init];
	
	NSString* preset = 0;
	if (!preset)
	{
		preset = AVCaptureSessionPresetHigh;
	}
	self.session.sessionPreset = preset;
	[[self session] beginConfiguration];
	if ([self.session canAddInput:captureInput])
	{
		[self.session addInput:captureInput];
	}
	if ([self.session canAddOutput:captureOutput])
	{
		[self.session addOutput:captureOutput];
	}
	[[self session] commitConfiguration];

	if (!self.captureVideoPreviewLayer)
	{
		self.captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
	}
	self.captureVideoPreviewLayer.frame = self.view.bounds;
	self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer: self.captureVideoPreviewLayer];
}
//---------------------------------------------
#pragma mark Utilities
//---------------------------------------------
- (void)checkDeviceAuthorizationStatus
{
	NSString *mediaType = AVMediaTypeVideo;
	
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
		if (granted)
		{
			[self setDeviceAuthorized:YES];
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				UIAlertController * alert = [UIAlertController
											 alertControllerWithTitle:@"SlopeFinder"
											 message:@"SlopeFinder doesn't have permission to use the Camera"
											 preferredStyle:UIAlertControllerStyleAlert];
				
				UIAlertAction* okButton = [UIAlertAction
											actionWithTitle:@"OK"
											style:UIAlertActionStyleDefault
											handler:^(UIAlertAction * action) {
												//Handle your ok button action here
											}];
				
				[alert addAction:okButton];
				[self presentViewController:alert animated:YES completion:nil];
				
				[self setDeviceAuthorized:NO];
			});
		}
	}];
}
//---------------------------------------------
+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == position)
		{
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}
//---------------------------------------------
- (void) setDirection:(double)valueDirection
{
	if( self.directionAnimating )
		return;
	[self.labelSlopeAngle.layer removeAllAnimations];
	self.directionAnimating = YES;
	[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear
					 animations:^{
						 self.labelSlopeAngle.transform = CGAffineTransformMakeRotation(-valueDirection / 180.0 * M_PI);
					 }
					 completion:^(BOOL finished){
						 self.directionAnimating = NO;
					 }];
	
}
//---------------------------------------------
@end
