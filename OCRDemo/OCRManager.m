//
//  OCRManager.m
//  OCRDemo
//
//  Created by ltp on 5/26/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "OCRManager.h"
#import <UIKit/UIKit.h>
	
@implementation OCRManager

-(NSString *)scanPic{
    NSString *res = @"";
    
    unsigned char *uc[88][25] = {0};
    unsigned char *grayImage[135][700] = {0};
    unsigned char *blackImage[135][88] = {0};
    return res;
}

- (UIImage *)getGreyScaleImage:(UIImage *)image{
    UIImage *retImg = nil;
    return retImg;
}

@end
