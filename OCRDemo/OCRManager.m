//
//  OCRManager.m
//  OCRDemo
//
//  Created by ltp on 5/26/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "OCRManager.h"
#import "template.h"

static const int kRed = 1;
static const int kGreen = 2;
static const int kBlue = 3;

@implementation OCRManager {
    NSInteger _width;
    NSInteger _height;
    uint8_t *_imageData;
}

- (instancetype)init{
    if (self = [super init]) {
        
    }
    return self;
}

-(NSString *)scanPic{
    NSString *res = @"";
    
//    uint8_t *uc[88][25] = {0};
//    uint8_t *grayImage[135][700] = {0};
//    uint8_t *blackImage[135][88] = {0};
    return res;
}

//edge detection
- (UIImage *)getEdge:(UIImage *)image{
    UIImage *retImage = nil;
    
    CGSize size = image.size;
    NSInteger width = size.width / 4;
    NSInteger height = size.height / 4;
    _width = width;
    _height = height;
    _imageData = malloc(sizeof(uint8_t) * width * height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(_imageData, width, height, 8, width, colorSpace, kCGImageAlphaNone);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    [self gaussianBlur];
    
    retImage = [self imageFromBitMap];
    return retImage;
}

-(void)cannyEdgeExtractWithTLow:(float)lowThreshhold THigh:(float)highThreshhold{
    //sobel operator
    int gx[3][3] = {
        { -1,  0,  1},
        { -2,  0,  2},
        { -1,  0,  1}
    };
    int gy[3][3] = {
        { -1,  0,  1},
        { -2,  0,  2},
        { -1,  0,  1}
    };
}

-(void)gaussianBlur{
    int blurMatrix[5][5] = {
        { 1,  4,  7,  4,  1},
        { 4, 16, 26, 16,  4},
        { 7, 26, 41, 26,  7},
        { 4, 16, 26, 16,  4},
        { 1,  4,  7,  4,  1},
    };
    uint8_t *blurImage = malloc(sizeof(uint8_t) * (_width - 5) * (_height - 5));
    for (int y = 0; y < _height - 5; y++) {
        for (int x = 0; x < _width - 5; x++) {
            int val = 0;
            for (int dy = 0; dy < 5; dy++) {
                for (int dx = 0; dx < 5; dx++) {
                    int pixel = _imageData[(y+dy) * _width + x + dx];
                    val += pixel * blurMatrix[dy][dx];
                }
            }
            blurImage[y*(_width-5)+x] = val/273;
        }
    }
    _width -= 5;
    _height -= 5;
    _imageData = blurImage;
}


//image binarization
- (UIImage *)getBlackImage:(UIImage *)image{
    UIImage *retImg = nil;
    
//    CGSize size = image.size;
//    NSInteger width = size.width;
//    NSInteger height = size.height;
    
    CGImageRef imageRef = [image CGImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *ciImage = [CIImage imageWithCGImage:imageRef];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:
                        @"inputImage", ciImage,
                        @"inputColor", [CIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f],
                        @"inputIntensity", [NSNumber numberWithFloat:1.0f],
                        nil];
    CIImage *filtedImage = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:filtedImage fromRect:[filtedImage extent]];
    retImg = [UIImage imageWithCGImage:cgImage];
    return retImg;
}

- (UIImage *)getGreyScaleImage:(UIImage *)image{
    
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

#pragma mark ---------utilities-----------

- (UIImage *)imageFromBitMap{
    UIImage *retImage = nil;
    uint8_t *retImageData = calloc(sizeof(uint32_t) * _width * _height, 1);
    for (int i = 0; i < _height * _width; i++) {
        uint8_t *rgbPixel = (uint8_t *)&retImageData[4*i];
        int pixel = _imageData[i];
        rgbPixel[kRed] = pixel;
        rgbPixel[kGreen] = pixel;
        rgbPixel[kBlue] = pixel;
    }
    
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef context=CGBitmapContextCreate(retImageData, _width, _height, 8, _width*sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipLast);
    CGImageRef image=CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    retImage=[UIImage imageWithCGImage:image];
    CGImageRelease(image);
    // make sure the data will be released by giving it to an autoreleased NSData
    [NSData dataWithBytesNoCopy:retImageData length:_width*_height];
    return retImage;
}

@end
