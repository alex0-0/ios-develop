//
//  CameraOverlay.m
//  OCRDemo
//
//  Created by ltp on 6/12/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "CameraOverlay.h"
#import "AppDelegate.h"
#define screenWidth [UIScreen mainScreen].bounds.size.width
#define cropWidth 125
#define cropHeight 88
#define ScreenHeight [[UIScreen mainScreen] bounds].size.height
#define ScreenWidth [[UIScreen mainScreen] bounds].size.width

@implementation CameraOverlay{
    CGFloat _width;
    CGFloat _height;
}

- (instancetype)init{
    if (self = [super init]) {
//        [((AppDelegate *)[UIApplication sharedApplication].delegate) setAllowRotation:TRUE];
//        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
//        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        _height = (ScreenWidth > ScreenHeight)?ScreenWidth : ScreenHeight;
        _width = (ScreenWidth < ScreenHeight)?ScreenWidth : ScreenHeight;
        [self initView];
    }
    return self;
}

- (void)initView{
//    self.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.6];
    self.opaque = NO;
    self.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 80, 50, 50, 50)];
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    [backButton setBackgroundColor:[UIColor blackColor]];
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    backButton.transform = CGAffineTransformMakeRotation(M_PI/2);
    [self addSubview:backButton];
    UIButton *flashButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth - 80, ScreenHeight - 100, 50, 50)];
    [flashButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [flashButton setTitle:@"flash" forState:UIControlStateNormal];
    [flashButton setBackgroundColor:[UIColor redColor]];
    [flashButton addTarget:self action:@selector(flashLight) forControlEvents:UIControlEventTouchUpInside];
    flashButton.transform = CGAffineTransformMakeRotation(M_PI/2);
    [self addSubview:flashButton];
    UIButton *tipButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 50, ScreenHeight - 50, 50, 50)];
    [tipButton setTitle:@"?" forState:UIControlStateNormal];
    [tipButton addTarget:self action:@selector(tip) forControlEvents:UIControlEventTouchUpInside];
    tipButton.transform = CGAffineTransformMakeRotation(M_PI/2);
    [self addSubview:tipButton];
}

- (void)back{
    if (_dismissImagePicker) {
        _dismissImagePicker();
    }
}

- (void)flashLight{
    if (_tapFlashLight) {
        _tapFlashLight();
    }
}

- (void)tip{
    if (_tapTip) {
        _tapTip();
    }
}
@end
