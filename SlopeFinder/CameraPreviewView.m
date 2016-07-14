//
//  CameraPreviewView.m
//  SlopeFinder
//
//  Created by Vlad Turchenko on 7/13/16.
//  Copyright © 2016 Vlad Turchenko. All rights reserved.
//

#import "CameraPreviewView.h"
#import <AVFoundation/AVFoundation.h>

@implementation CameraPreviewView

//---------------------------------------------
+ (Class)layerClass
{
	return [AVCaptureVideoPreviewLayer class];
}
//---------------------------------------------
- (AVCaptureSession *)session
{
	return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}
//---------------------------------------------
- (void)setSession:(AVCaptureSession *)session
{
	[(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}
//---------------------------------------------
//---------------------------------------------
//---------------------------------------------
@end
