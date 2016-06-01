//
//  OCRManager.m
//  OCRDemo
//
//  Created by ltp on 5/26/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "OCRManager.h"
#import <UIKit/UIKit.h>
	
@implementation OCRManager {
    NSInteger _width;
    NSInteger _height;
}

- (instancetype)init{
    if (self = [super init]) {
        
    }
    return self;
}

-(NSString *)scanPic{
    NSString *res = @"";
    
    unsigned char *uc[88][25] = {0};
    unsigned char *grayImage[135][700] = {0};
    unsigned char *blackImage[135][88] = {0};
    return res;
}

- (UIImage *)getGreyScaleImage:(UIImage *)image{
    UIImage *retImg = nil;
    
    const int kRed = 1;
    const int kGreen = 2;
    const int kBlue = 3;
    
    int colors = kRed | kGreen | kBlue;
    CGSize size = image.size;
    uint32_t *bitMap = (uint32_t *)malloc(_width * _height * sizeof(uint32_t));
    memset(bitMap, 0, _width * _height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contex = CGBitmapContextCreate(bitMap, _width, _height, 8, _width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextSetInterpolationQuality(contex, kCGInterpolationHigh);
    return retImg;
}

@end
