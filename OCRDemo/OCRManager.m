//
//  OCRManager.m
//  OCRDemo
//
//  Created by ltp on 5/26/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "OCRManager.h"
	
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

- (UIImage *)getBlackImage:(UIImage *)image{
    UIImage *retImg = nil;
    return retImg;
}

- (UIImage *)getGreyScaleImage:(UIImage *)image{

    const int kRed = 1;
    const int kGreen = 2;
    const int kBlue = 3;
    
//    int colors = kRed | kGreen | kBlue;
    CGSize size = image.size;
    NSInteger width = size.width;
    NSInteger height = size.height;
    uint32_t *bitMap = (uint32_t *)malloc(width * height * sizeof(uint32_t));
    memset(bitMap, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(bitMap, width, height, 8, width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            uint8_t *rgbPixel = (uint8_t *)&bitMap[y * width + x];
            //recommended by wiki
            uint32_t gray = 0.3 * rgbPixel[kRed] + 0.59 * rgbPixel[kBlue] + 0.11 * rgbPixel[kBlue];
            rgbPixel[kRed] = gray;
            rgbPixel[kGreen] = gray;
            rgbPixel[kBlue] = gray;
        }
    }
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(bitMap);
    
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    return returnImage;
}

@end
