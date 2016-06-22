//
//  CameraOverlay.m
//  OCRDemo
//
//  Created by ltp on 6/12/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "CameraOverlay.h"
#import "AppDelegate.h"

#define ScreenHeight [[UIScreen mainScreen] bounds].size.height
#define ScreenWidth [[UIScreen mainScreen] bounds].size.width

#define kDefaultWidth 320.0

void addMask(UIView *containerView, CGRect transparentRect, UIColor *maskColor){
    CGPoint origin = transparentRect.origin;
    CGSize size = transparentRect.size;
    if (origin.y > 0) {
        UIView *upperMask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, origin.y)];
        upperMask.backgroundColor = maskColor;
        [containerView addSubview:upperMask];
    }
    if (origin.x > 0) {
        UIView *leftMask = [[UIView alloc] initWithFrame:CGRectMake(0, origin.y, origin.x, size.height)];
        leftMask.backgroundColor = maskColor;
        [containerView addSubview:leftMask];
    }
    if (origin.x + size.width < ScreenWidth) {
        UIView *rightMask = [[UIView alloc] initWithFrame:CGRectMake(origin.x + size.width, origin.y, ScreenWidth - (origin.x + size.width), size.height)];
        rightMask.backgroundColor = maskColor;
        [containerView addSubview:rightMask];
    }
    if (origin.y + size.height < ScreenHeight) {
        UIView *bottomMask = [[UIView alloc] initWithFrame:CGRectMake(0, origin.y + size.height, ScreenWidth, ScreenHeight - (origin.y + size.height))];
        bottomMask.backgroundColor = maskColor;
        [containerView addSubview: bottomMask];
    }
}

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
    float scaleRatio = 1.0;//ScreenWidth / kDefaultWidth;
//    self.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.6];
    self.opaque = NO;
    self.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    
    //init mask view
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    CGRect passportRect = CGRectMake((ScreenWidth - 249 * scaleRatio) / 2, (ScreenHeight - 354 * scaleRatio) / 2, 249 * scaleRatio, 354 * scaleRatio);
    UIView *passportMask = [[UIView alloc] initWithFrame:passportRect];
    [container addSubview:passportMask];
    UIView *innerOverlay = [[UIView alloc] initWithFrame:CGRectMake(56 * scaleRatio, 0, 193 * scaleRatio, 354 * scaleRatio)];
    innerOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65];
    [passportMask addSubview:innerOverlay];
    UIImageView *barCodeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"barcode"]];
    barCodeView.transform = CGAffineTransformMakeRotation(M_PI/2);
    barCodeView.frame = CGRectMake(0, 0, 56 * scaleRatio, passportMask.frame.size.height);
    [passportMask addSubview:barCodeView];
    
    //CGRect for cropping the passport from camera preview. Due to the horizontal display, the frame has to rotate PI
    _idStringRect = CGRectMake(0, 193 * scaleRatio, 354 * scaleRatio, 112 * scaleRatio);
    _passportRect = CGRectMake(passportRect.origin.y * scaleRatio, passportRect.origin.x * scaleRatio, passportRect.size.height * scaleRatio, passportRect.size.width * scaleRatio);
    
    addMask(container, passportRect, [[UIColor blackColor] colorWithAlphaComponent:0.85]);
    UILabel *tipLabel = [[UILabel alloc] init];
    tipLabel.numberOfLines = 1;
    tipLabel.font = [UIFont systemFontOfSize:13.0];
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.text = @"请将护照个人资料页底部条码置于下方框内";
    CGSize tipLabelSize = [tipLabel.text sizeWithAttributes:@{NSFontAttributeName:tipLabel.font}];
    tipLabel.frame = CGRectMake((ScreenWidth - tipLabelSize.width) / 2, ScreenHeight / 2, tipLabelSize.width, tipLabelSize.height);
    tipLabel.transform = CGAffineTransformMakeRotation(M_PI/2);
    [container addSubview:tipLabel];
    [self addSubview:container];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth - 80, 50, 50, 50)];
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
    UIButton *tipButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth - 50, ScreenHeight - 50, 50, 50)];
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
