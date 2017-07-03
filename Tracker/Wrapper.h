//
//  Wrapper.h
//  Tracker
//
//  Created by Jack Guo on 9/7/16.
//  Copyright © 2016 InPsi Inc. All rights reserved.
//

enum TrackingStatus {INIT,TRACKING,SCALEFAILED,OUT,DRIFT};
const tracking::PtrackParam PtrackParamWrapper = tracking::PtrackParam();

@interface PTrackerWrapper : NSObject
- (id)init:(tracking::PtrackParam)param;
- (TrackingStatus)init:(CMSampleBufferRef)sampleBuffer withX:(float)x withY:(float)y withHeight:(float)height withWidth:(float)width;
- (TrackingStatus)track:(CMSampleBufferRef)sampleBuffer;
- (NSDictionary *) getRoi;
- (void) resetRoi:(int)x withY:(int)y withHeight:(int)height withWidth:(int)width;
- (TrackingStatus) convertTrackingStatus:(tracking::TrackingStatus)status;
@end