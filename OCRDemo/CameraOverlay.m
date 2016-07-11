//
//  CameraOverlay.m
//  OCRDemo
//
//  Created by ltp on 6/12/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "CameraOverlay.h"

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

- (instancetype)init:(CameraOverlayType)type{
    if (self = [super init]) {
        _height = (ScreenWidth > ScreenHeight)?ScreenWidth : ScreenHeight;
        _width = (ScreenWidth < ScreenHeight)?ScreenWidth : ScreenHeight;
        [self initView:type];
    }
    return self;
}

- (void)initView:(CameraOverlayType)type{
    float scaleRatio = ScreenWidth / kDefaultWidth;
    //    self.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.6];
    self.opaque = NO;
    self.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    
    //init mask view
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    switch (type) {
        case CameraOverlayTypePassport:
        {
            CGRect passportRect = CGRectMake((ScreenWidth - 249 * scaleRatio) / 2, (ScreenHeight - 354 * scaleRatio) / 2, 249 * scaleRatio, 354 * scaleRatio);
            UIView *passportMask = [[UIView alloc] initWithFrame:passportRect];
            UIView *innerOverlay = [[UIView alloc] initWithFrame:CGRectMake(56 * scaleRatio, 0, 193 * scaleRatio, 354 * scaleRatio)];
            innerOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65];
            [passportMask addSubview:innerOverlay];
            UIImageView *barCodeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"barcode"]];
            barCodeView.transform = CGAffineTransformMakeRotation(M_PI/2);
            barCodeView.frame = CGRectMake(0, 0, 56 * scaleRatio, passportMask.frame.size.height);
            [passportMask addSubview:barCodeView];
            [container addSubview:passportMask];
            addMask(container, passportRect, [[UIColor blackColor] colorWithAlphaComponent:0.85]);
            
            UILabel *tipLabel = [[UILabel alloc] init];
            tipLabel.numberOfLines = 1;
            tipLabel.font = [UIFont systemFontOfSize:13.0];
            tipLabel.textColor = [UIColor whiteColor];
            tipLabel.text = @"请将护照个人资料页底部条码置于下方框内";
            CGSize tipLabelSize = [tipLabel.text sizeWithAttributes:@{NSFontAttributeName:tipLabel.font}];
            tipLabel.transform = CGAffineTransformMakeRotation(M_PI/2);
            tipLabel.frame = CGRectMake((ScreenWidth - tipLabelSize.height) / 2 - 30 * scaleRatio, (ScreenHeight - tipLabelSize.width) / 2, tipLabelSize.height, tipLabelSize.width);
            [container addSubview:tipLabel];
            
            UILabel *ligthtTipLabel = [[UILabel alloc] init];
            ligthtTipLabel.numberOfLines = 1;
            ligthtTipLabel.font = [UIFont systemFontOfSize:13.0];
            ligthtTipLabel.textColor = [UIColor whiteColor];
            ligthtTipLabel.text = @"注意证件表面不要有反光";
            tipLabelSize = [ligthtTipLabel.text sizeWithAttributes:@{NSFontAttributeName:ligthtTipLabel.font}];
            ligthtTipLabel.transform = CGAffineTransformMakeRotation(M_PI/2);
            ligthtTipLabel.frame = CGRectMake((ScreenWidth - tipLabelSize.height) / 2 - 30 * scaleRatio - tipLabel.frame.size.width, (ScreenHeight - tipLabelSize.width) / 2, tipLabelSize.height, tipLabelSize.width);
            [container addSubview:ligthtTipLabel];
        }
            break;
        case CameraOverlayTypeIDCard:
        {
            CGRect cardRect = CGRectMake((ScreenWidth - 232 * scaleRatio) / 2, (ScreenHeight - 365 * scaleRatio) / 2, 232 * scaleRatio, 365 * scaleRatio);
            addMask(container, cardRect, [[UIColor blackColor] colorWithAlphaComponent:0.85]);
            UILabel *tipLabel = [[UILabel alloc] init];
            tipLabel.numberOfLines = 1;
            tipLabel.font = [UIFont systemFontOfSize:14.0];
            tipLabel.textColor = [UIColor whiteColor];
            tipLabel.text = @"请将身份证置于框内并尝试对齐边缘";
            CGSize tipLabelSize = [tipLabel.text sizeWithAttributes:@{NSFontAttributeName:tipLabel.font}];
            tipLabel.transform = CGAffineTransformMakeRotation(M_PI/2);
            tipLabel.frame = CGRectMake(cardRect.origin.x - 12 * scaleRatio - tipLabel.frame.size.height, (ScreenHeight - tipLabelSize.width) / 2, tipLabelSize.height, tipLabelSize.width);
            [container addSubview:tipLabel];
        }
            break;
        default:
            break;
    }
    
    [self addSubview:container];
    
    UIButton *backButton = [[UIButton alloc] init];
    [backButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
    [backButton setBackgroundColor:[UIColor clearColor]];
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    backButton.transform = CGAffineTransformMakeRotation(M_PI/2);
    backButton.frame = CGRectMake(ScreenWidth - 33 - 5, 10, 33, 33);
    [self addSubview:backButton];
    UIButton *flashButton = [[UIButton alloc] init];
    [flashButton setBackgroundColor:[UIColor clearColor]];
    [flashButton setImage:[UIImage imageNamed:@"light_off"] forState:UIControlStateNormal];
    [flashButton addTarget:self action:@selector(flashLight:) forControlEvents:UIControlEventTouchUpInside];
    flashButton.transform = CGAffineTransformMakeRotation(M_PI/2);
    flashButton.frame = CGRectMake(ScreenWidth - 33 - 5, ScreenHeight - 33 - 10, 33, 33);
    [self addSubview:flashButton];
    UIButton *tipButton = [[UIButton alloc] init];
    [tipButton setTitle:@"?" forState:UIControlStateNormal];
    [tipButton addTarget:self action:@selector(tip) forControlEvents:UIControlEventTouchUpInside];
    [tipButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
    tipButton.transform = CGAffineTransformMakeRotation(M_PI/2);
    tipButton.frame = CGRectMake(flashButton.frame.origin.x, flashButton.frame.origin.y - 10 - 33, 33, 33);
    [self addSubview:tipButton];
}

- (void)back{
    if (_dismissImagePicker) {
        _dismissImagePicker();
    }
}

- (void)flashLight:(id)sender{
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
