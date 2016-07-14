//
//  SlopeData.h
//  SlopeFinder
//
//  Created by Vlad Turchenko on 7/13/16.
//  Copyright © 2016 Vlad Turchenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SlopeData : NSObject

@property float slopeAngle;
@property float slopeAngleDisplay;
@property float slopeDirection;

-(void) start;
-(void) stop;
@end
