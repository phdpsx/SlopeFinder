//
//  CameraPreviewView.h
//  SlopeFinder
//
//  Created by Vlad Turchenko on 7/13/16.
//  Copyright © 2016 Vlad Turchenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface CameraPreviewView : UIView

@property (nonatomic) AVCaptureSession *session;

@end
