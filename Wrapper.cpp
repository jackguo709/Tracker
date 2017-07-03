//
//  Wrapper.cpp
//  Tracker
//
//  Created by Jack Guo on 9/9/16.
//  Copyright © 2016 InPsi Inc. All rights reserved.
//

#include <opencv2/opencv.hpp>
#include "kcftracker.hpp"
#include "Wrapper.hpp"

KCFTracker

int init(void* data, int row, int col,int type){
    cv::Mat mat =cv::Mat((int)bufferHeight, (int)bufferWidth, CV_8UC3, data);
    cv::cvtColor(mat,mat,CV_BGR2GRAY);
    
    return 0;
}
int track(void* data, int row, int col,int type){
    return 0;
}
int setRoi(int x,int y,int w,int h){
    return 0;
}
int getRoi(int* x,int* y,int* w,int* h){
    return 0;
}