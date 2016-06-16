//
//  OverlayViewController.m
//  OCRDemo
//
//  Created by ltp on 6/14/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "OverlayViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "LibScanPassport.h"

@interface OverlayViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@end

@implementation OverlayViewController{
    UIView *_tipView;
    CameraOverlay *_overlay;
    AVCaptureSession *_captureSession;
    AVCaptureVideoPreviewLayer *_previewLayer;
//    AVCaptureStillImageOutput *_stillImageOutput;
//    CIDetector *_faceDetector;
    int8_t *_bitMap;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initCapture];
    [self initOverlayView];
    [self initTipView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self ocr:[UIImage imageNamed:@"passport.jpg"]];
//    [_captureSession startRunning];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initCapture{
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    if (!captureInput) {
        return;
    }
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    dispatch_queue_t cameraQueue = dispatch_queue_create("cameraQueue", NULL);
    [captureOutput setSampleBufferDelegate:self queue:cameraQueue];
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInteger:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSetting = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSetting];
    _captureSession = [[AVCaptureSession alloc] init];
    NSString *preset = 0;
    if (!preset) {
        preset = AVCaptureSessionPresetMedium;
    }
    _captureSession.sessionPreset = preset;
    if ([_captureSession canAddInput:captureInput]) {
        [_captureSession addInput:captureInput];
    }
    if ([_captureSession canAddOutput:captureOutput]) {
        [_captureSession addOutput:captureOutput];
    }
    if (!_previewLayer) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    }
    CGRect bounds = self.view.layer.bounds;
    _previewLayer.bounds = bounds;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_previewLayer setPosition:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    [self.view.layer addSublayer:_previewLayer];
}

- (void)initTipView{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat width = screenSize.width;
    CGFloat height = screenSize.height;
    UIView *containerView = [[UIView alloc] init];
    
    _tipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    _tipView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    UILabel *tips = [[UILabel alloc] init];
    tips.numberOfLines = 0;
    tips.font = [UIFont systemFontOfSize:12.0];
    tips.textColor = [UIColor whiteColor];
    tips.text = @"请确保：\n\
    \u2022 证件为有效证件；\n\
    \u2022 扫描角度正对证件，无倾斜、无抖动；\n\
    \u2022 证件无反光且清晰。若灯光过暗，请打开闪光灯\n\
      或至明亮的地方扫描。\n\
    \u2022 网络顺畅";
    CGSize labelSize = [tips.text sizeWithAttributes:@{NSFontAttributeName:tips.font}];
    tips.frame = CGRectMake(0, 0, labelSize.width, labelSize.height);
    [containerView addSubview:tips];
    
    UIButton *okButton = [[UIButton alloc] initWithFrame:CGRectMake(tips.frame.origin.x, tips.frame.origin.y + labelSize.height, labelSize.width, 30)];
    [okButton setTitle:@"知道了" forState:UIControlStateNormal];
    [okButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [okButton setBackgroundColor:[UIColor whiteColor]];
    [okButton addTarget:self action:@selector(dismissTipView) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:okButton];
    
    containerView.frame = CGRectMake((width - labelSize.width) / 2, (height - labelSize.height) / 2, labelSize.width, labelSize.height + okButton.frame.size.height);
    [containerView setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    [_tipView addSubview:containerView];
    [self.view addSubview:_tipView];
}

- (void)initOverlayView{
    _overlay = [[CameraOverlay alloc] init];
    _overlay.frame = [UIScreen mainScreen].bounds;
    __weak typeof(self) weakSelf = self;
    _overlay.tapFlashLight = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self flashLight];
    };
    _overlay.dismissImagePicker = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self back];
    };
    _overlay.tapTip = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self showTip];
    };
    [self.view addSubview:_overlay];
}

- (void)dismissTipView{
    [_tipView removeFromSuperview];
}

- (void)flashLight{
    AVCaptureDevice *flashLight = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([flashLight isTorchAvailable] && [flashLight isTorchModeSupported:AVCaptureTorchModeOn]) {
        BOOL success = [flashLight lockForConfiguration:nil];
        if (success) {
            if ([flashLight isTorchActive]) {
                [flashLight setTorchMode:AVCaptureTorchModeOff];
            }
            else {
                [flashLight setTorchMode:AVCaptureTorchModeOn];
            }
            [flashLight unlockForConfiguration];
        }
    }
}

- (void)back{
    [_captureSession stopRunning];
    if ([self presentingViewController] != nil) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
//    else {
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }
//    [_imagePicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)showTip{
    [self.view addSubview:_tipView];
}

#pragma mark -------------AVCaptureVideoDataOutputSampleBufferDelegate   -------------------

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

    CIImage *ciimage = [CIImage imageWithCVPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
    CIImage *croppedRecImage = nil;
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:[CIContext contextWithOptions:nil] options:nil];
    CIDetector *rectangleDetector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:[CIContext contextWithOptions:nil] options:nil];
    NSArray *rectangleFeatures = [rectangleDetector featuresInImage:ciimage options:nil];
    for (CIFeature *feature in rectangleFeatures) {
        if ( ![feature isKindOfClass:[CIRectangleFeature class]]) {
            continue;
        }

        CIVector *cropRect = [CIVector vectorWithCGRect:feature.bounds];
        CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
        [cropFilter setValue:ciimage forKey:@"inputImage"];
        [cropFilter setValue:cropRect forKey:@"inputRectangle"];
        croppedRecImage = [cropFilter valueForKey:@"outputImage"];
    }
    if (croppedRecImage) {
        NSArray *faceFeatures = [faceDetector featuresInImage:croppedRecImage options:nil];
        for (CIFeature *feature in faceFeatures) {
            if ( [feature isKindOfClass:[CIFaceFeature class]]) {
                CIVector *cropRect = [CIVector vectorWithCGRect:feature.bounds];
                CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
                [cropFilter setValue:ciimage forKey:@"inputImage"];
                [cropFilter setValue:cropRect forKey:@"inputRectangle"];
                CIImage *faceImage = [cropFilter valueForKey:@"outputImage"];
                UIImage *tmpImage = [UIImage imageWithCGImage:[[CIContext contextWithOptions:nil] createCGImage:croppedRecImage fromRect:croppedRecImage.extent]];
                [self ocr:tmpImage];
            }
        }
    }
    
}

- (void)ocr:(UIImage *)image{
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    _bitMap = malloc([data length] * sizeof(char));
    memcpy(_bitMap, [data bytes], [data length]);
    int pixelWidth = image.size.width * [UIScreen mainScreen].scale;
    int pixelHeight = image.size.height * [UIScreen mainScreen].scale;
    CGRect clippedRect  = CGRectMake(0, image.size.height - image.size.width * 0.158, image.size.width, image.size.width * 0.158);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], clippedRect);
    UIImage *newImage   = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    char *result = LibScanPassport_scanByte(_bitMap, pixelWidth, pixelHeight, 0, image.size.height - image.size.width * 0.158, image.size.width, image.size.width * 0.158); //0.158 = 1/6.33
    NSString *number = [NSString stringWithUTF8String:result];
    NSLog(@"%@",number);
}

@end
