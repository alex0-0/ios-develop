//
//  CameraOverlay.m
//  OCRDemo
//
//  Created by ltp on 6/12/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "CameraOverlay.h"
#import "AppDelegate.h"
//#import "CaptureSessionManager.h"

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define cropWidth 125
#define cropHeight 88
#define ScreenHeight [[UIScreen mainScreen] bounds].size.height
#define ScreenWidth [[UIScreen mainScreen] bounds].size.width

@implementation CameraOverlay{
    UIView *_tipView;
    CGFloat _width;
    CGFloat _height;
}

- (instancetype)init{
    if (self = [super init]) {
//        [((AppDelegate *)[UIApplication sharedApplication].delegate) setAllowRotation:TRUE];
//        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
//        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        _width = (ScreenWidth > ScreenHeight)?ScreenWidth : ScreenHeight;
        _height = (ScreenWidth < ScreenHeight)?ScreenWidth : ScreenHeight;
        [self initView];
    }
    return self;
}

- (void)initView{
    self.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.6];
    self.opaque = NO;
    self.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    [self initTipView];
    [self addSubview:_tipView];
}

- (void)initTipView{
    _tipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _width, _height)];
    _tipView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    UILabel *tips = [[UILabel alloc] init];
    tips.numberOfLines = 0;
    tips.font = [UIFont systemFontOfSize:12.0];
    tips.textColor = [UIColor whiteColor];
    tips.text = @"请确保：\n\
        \u2022 证件为有效证件；\n\
        \u2022 扫描角度正对证件，无倾斜、无抖动；\n\
        \u2022 证件无反光且清晰。若灯光过暗，请打开闪光灯或至明亮的地方扫描。\n\
        \u2022 网络顺畅";
    CGSize labelSize = [tips.text sizeWithAttributes:@{NSFontAttributeName:tips.font}];
    tips.frame = CGRectMake((_width - labelSize.width) / 2, (_height - labelSize.height) / 2, labelSize.width, labelSize.height);
    [_tipView addSubview:tips];
    
    UIButton *okButton = [[UIButton alloc] initWithFrame:CGRectMake(tips.frame.origin.x, tips.frame.origin.y + labelSize.height, _width / 2, 30)];
    [okButton setTitle:@"知道了" forState:UIControlStateNormal];
    [okButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [okButton setBackgroundColor:[UIColor whiteColor]];
    [okButton addTarget:self action:@selector(dismissTipView) forControlEvents:UIControlEventTouchUpInside];
    [_tipView addSubview:okButton];
}

- (void)dismissTipView{
    [_tipView removeFromSuperview];
}

- (void)drawRect:(CGRect)rect{
    
}

@end
