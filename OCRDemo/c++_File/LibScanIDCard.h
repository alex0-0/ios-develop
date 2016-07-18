//
//  LibScanIDCard.h
//  OCRDemo
//
//  Created by ltp on 7/12/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#ifndef LibScanIDCard_h
#define LibScanIDCard_h
#ifdef __cplusplus
extern "C" {
#endif

    char* LibScanIDCard_scanByteIDCard(int8_t *arr, int hw, int hh, int x, int y, int w, int h);
    char* LibScanPassport_scanByte(int8_t *arr,int hw,int hh,int x,int y,int w,int h);
    
#ifdef __cplusplus
}
#endif
#endif /* LibScanIDCard_h */
