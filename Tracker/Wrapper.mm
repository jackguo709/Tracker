//
//  Wrapper.m
//  Tracker
//
//  Created by Jack Guo on 9/7/16.
//  Copyright © 2016 InPsi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include "Wrapper.h"

@interface PTrackerWrapper()
@property tracking::Ptracker *tracker;
@end

@implementation PTrackerWrapper : NSObject
cv::Rect_<float> _roi;

- (id)init:(tracking::PtrackParam)param {
    if (self = [super init]) {
        self.tracker = new tracking::Ptracker(para);
    }
    return self;
}

- (TrackingStatus)init:(CMSampleBufferRef)sampleBuffer withX:(float)x withY:(float)y withHeight:(float)height withWidth:(float)width {
    cv::Rect_<float> roi = cv::Rect_<float>(x, y, height, width);
    cv::Mat frame = [self parseBuffer:sampleBuffer];
    return [self convertTrackingStatus:self.tracker->init(frame, roi)];
}

- (TrackingStatus)track: (CMSampleBufferRef)sampleBuffer {
    cv::Mat frame = [self parseBuffer:sampleBuffer];
    return [self convertTrackingStatus:self.tracker->track(frame)];
}

- (NSDictionary *) getRoi {
    NSDictionary *rect = @{
        @"x" : [NSNumber numberWithInt:_roi.x],
        @"y" : [NSNumber numberWithInt:_roi.y],
        @"width" : [NSNumber numberWithInt:_roi.width],
        @"height" : [NSNumber numberWithInt:_roi.height]
        };
    return rect;
}

- (void) resetRoi:(int)x withY:(int)y withHeight:(int)height withWidth:(int)width {
    _roi = cv::Rect(x, y, height, width);
}

- (TrackingStatus) convertTrackingStatus:(tracking::TrackingStatus)status {
    switch (status) {
        case tracking::INIT:
            return INIT;
            break;
        case tracking::TRACKING:
            return TRACKING;
            break;
        case tracking::SCALEFAILED:
            return SCALEFAILED;
            break;
        case tracking::OUT:
            return OUT;
            break;
        case tracking::DRIFT:
            return DRIFT;
            break;
        default:
            break;
    }
}

- (cv::Mat) parseBuffer:(CMSampleBufferRef) sampleBuffer {
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    cv::Mat mat =cv::Mat((int)bufferHeight, (int)bufferWidth, CV_8UC1, pixel);
    cv::cvtColor(mat,mat,CV_HSV2BGR);
    cv::cvtColor(mat,mat,CV_BGR2GRAY);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return mat;
}
@end