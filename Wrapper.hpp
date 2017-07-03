//
//  Wrapper.hpp
//  Tracker
//
//  Created by Jack Guo on 9/9/16.
//  Copyright © 2016 InPsi Inc. All rights reserved.
//

#ifndef Wrapper_hpp
#define Wrapper_hpp

int init(void* data, int row, int col,int type);
int track(void* data, int row, int col,int type);
int setRoi(int x,int y,int w,int h);
int getRoi(int* x,int* y,int* w,int* h);

#endif /* Wrapper_hpp */
