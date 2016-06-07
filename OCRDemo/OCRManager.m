//
//  OCRManager.m
//  OCRDemo
//
//  Created by ltp on 5/26/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "OCRManager.h"
#import "template.h"

#define NOEDGE 0
#define POSSIBLE_EDGE 128
#define EDGE 255

static const int kRed = 1;
static const int kGreen = 2;
static const int kBlue = 3;

@implementation OCRManager {
    NSInteger _width;
    NSInteger _height;
    uint8_t *_imageData;
    int *_gradx;
    int *_grady;
    int *_mag;
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
    
    [self cannyEdgeExtractWithTLow:0.3 THigh:0.7];
    
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
        {  1,  2,  1},
        {  0,  0,  0},
        { -1, -2,  1}
    };
    NSInteger retHeight = _height - 3;
    NSInteger retWidth = _width - 3;
    int *diffx = malloc(sizeof(int) * retWidth * retHeight);    //horizonal derivative
    int *diffy = malloc(sizeof(int) * retWidth * retHeight);    //vertical derivative
    int *mag = malloc(sizeof(int) * retWidth * retHeight);      //gradient magnitude
    memset(diffx, 0, sizeof(int) * retWidth * retHeight);
    memset(diffy, 0, sizeof(int) * retWidth * retHeight);
    memset(mag, 0, sizeof(int) * retWidth * retHeight);
    //compute magnitude
    for (int y = 0; y < retHeight; y++) {
        for (int x = 0; x < retWidth; x++) {
            int derX = 0;
            int derY = 0;
            for (int dy = 0; dy < 3; dy++) {
                for (int dx = 0; dx < 3; dx++) {
                    int pixel = _imageData[y * _width + x];
                    derX += pixel * gx[dy][dx];
                    derY += pixel * gy[dy][dx];
                }
            }
            mag[y * retWidth + x] = abs(derX) + abs(derY);
            diffx[y * retWidth + x] = derX;
            diffy[y * retWidth + x] = derY;
        }
    }
    _mag = mag;
    _gradx = diffx;
    _grady = diffy;
    _width = retWidth;
    _height = retHeight;
    //non max suppression
    uint8_t *filteredImage = malloc(sizeof(uint8_t) * retWidth * retHeight);
    memset(filteredImage, 0, sizeof(uint8_t) * retWidth * retHeight);
    [self suppressNonMaxium:filteredImage];
    
    free(diffx);
    free(diffy);
    
//    uint8_t *edge = malloc(sizeof(uint8_t)*retHeight*retWidth);
//    memset(edge, 0, sizeof(uint8_t) * retWidth * retHeight);
//    
//    free(filteredImage);
    
    _imageData = filteredImage ;
}

- (void)applyHystesis:(int *)possibleEdges highThreshold:(float)highT lowThreshold:(float)lowT{
    int edgesCount = 0, pos = 0, numEdges = 0, maxMag = 0;
    int hist[32768] = {0};  //256*8*16
}

- (void)suppressNonMaxium:(uint8_t*)result{
    int rowCount, colCount, count;
    int *magRowPtr, *magPtr;
    int *gxRowPtr, *gxPtr;
    int *gyRowPtr, *gyPtr;
    int m00, gx = 0, gy = 0, z1 = 0, z2 = 0;
    float mag1, mag2, xperp = 0.0f, yperp = 0.0f; //magnitude of beside points, x perpendicular, y perpendicular
    uint8_t *resultRowPtr, *resultPtr;

    /****************************************************************************
     * Zero the edges of the result image.
     ****************************************************************************/
    for (count = 0, resultPtr = result, resultRowPtr = result + _width * (_height - 1) + 1;
         count < _width;
         count++, resultPtr++, resultRowPtr++) {
         *resultRowPtr = *resultPtr = (uint8_t)0;
    }
    for (count = 0, resultPtr = result, resultRowPtr = result + _width - 1;
         count < _height;
         count++, resultRowPtr++, resultPtr++) {
         *resultRowPtr = *resultPtr = (uint8_t)0;
    }
    /****************************************************************************
     * Suppress non-maximum points.
     ****************************************************************************/
    for(rowCount = 1, magRowPtr = _mag + _width + 1, gxRowPtr = _gradx + _width + 1,
        gyRowPtr = _grady + _width + 1, resultRowPtr = result + _width + 1;
        rowCount < _height - 2;
        rowCount++, magRowPtr += _width, gyRowPtr += _width, gxRowPtr += _width,
        resultRowPtr += _width){
        for(colCount = 1, magPtr = magRowPtr, gxPtr = gxRowPtr, gyPtr = gyRowPtr, resultPtr = resultRowPtr;
            colCount < _width-2;
            colCount++,magPtr++,gxPtr++,gyPtr++,resultPtr++){
            m00 = *magPtr;
            if(m00 == 0){
                *resultPtr = (unsigned char) NOEDGE;
            }
            else{
                xperp = -(gx = *gxPtr)/((float)m00);
                yperp = (gy = *gyPtr)/((float)m00);
            }
            //linear interpolation?
            if(gx >= 0){
                if(gy >= 0){
                    if (gx >= gy)
                    {
                        /* 111 */
                        /* Left point */
                        z1 = *(magPtr - 1);
                        z2 = *(magPtr - _width - 1);
                        
                        mag1 = (m00 - z1)*xperp + (z2 - z1)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr + 1);
                        z2 = *(magPtr + _width + 1);
                        
                        mag2 = (m00 - z1)*xperp + (z2 - z1)*yperp;
                    }
                    else
                    {
                        /* 110 */
                        /* Left point */
                        z1 = *(magPtr - _width);
                        z2 = *(magPtr - _width - 1);
                        
                        mag1 = (z1 - z2)*xperp + (z1 - m00)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr + _width);
                        z2 = *(magPtr + _width + 1);
                        
                        mag2 = (z1 - z2)*xperp + (z1 - m00)*yperp;
                    }
                }
                else
                {
                    if (gx >= -gy)
                    {
                        /* 101 */
                        /* Left point */
                        z1 = *(magPtr - 1);
                        z2 = *(magPtr + _width - 1);
                        
                        mag1 = (m00 - z1)*xperp + (z1 - z2)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr + 1);
                        z2 = *(magPtr - _width + 1);
                        
                        mag2 = (m00 - z1)*xperp + (z1 - z2)*yperp;
                    }
                    else
                    {
                        /* 100 */
                        /* Left point */
                        z1 = *(magPtr + _width);
                        z2 = *(magPtr + _width - 1);
                        
                        mag1 = (z1 - z2)*xperp + (m00 - z1)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr - _width);
                        z2 = *(magPtr - _width + 1);
                        
                        mag2 = (z1 - z2)*xperp  + (m00 - z1)*yperp;
                    }
                }
            }
            else
            {
                if ((gy = *gyPtr) >= 0)
                {
                    if (-gx >= gy)
                    {
                        /* 011 */
                        /* Left point */
                        z1 = *(magPtr + 1);
                        z2 = *(magPtr - _width + 1);
                        
                        mag1 = (z1 - m00)*xperp + (z2 - z1)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr - 1);
                        z2 = *(magPtr + _width - 1);
                        
                        mag2 = (z1 - m00)*xperp + (z2 - z1)*yperp;
                    }
                    else
                    {
                        /* 010 */
                        /* Left point */
                        z1 = *(magPtr - _width);
                        z2 = *(magPtr - _width + 1);
                        
                        mag1 = (z2 - z1)*xperp + (z1 - m00)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr + _width);
                        z2 = *(magPtr + _width - 1);
                        
                        mag2 = (z2 - z1)*xperp + (z1 - m00)*yperp;
                    }
                }
                else
                {
                    if (-gx > -gy)
                    {
                        /* 001 */
                        /* Left point */
                        z1 = *(magPtr + 1);
                        z2 = *(magPtr + _width + 1);
                        
                        mag1 = (z1 - m00)*xperp + (z1 - z2)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr - 1);
                        z2 = *(magPtr - _width - 1);
                        
                        mag2 = (z1 - m00)*xperp + (z1 - z2)*yperp;
                    }
                    else
                    {
                        /* 000 */
                        /* Left point */
                        z1 = *(magPtr + _width);
                        z2 = *(magPtr + _width + 1);
                        
                        mag1 = (z2 - z1)*xperp + (m00 - z1)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr - _width);
                        z2 = *(magPtr - _width - 1);
                        
                        mag2 = (z2 - z1)*xperp + (m00 - z1)*yperp;
                    }
                }
            } 
            
            /* Now determine if the current point is a maximum point */
            
            if ((mag1 > 0.0) || (mag2 > 0.0))
            {
                *resultPtr = (unsigned char) NOEDGE;
            }
            else
            {    
                if (mag2 == 0.0)
                    *resultPtr = (unsigned char) NOEDGE;
                else
                    *resultPtr = (unsigned char) POSSIBLE_EDGE;
            }
        } 
    }
}

- (void)gaussianBlur{
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
