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

int getPixelByCharImage(int *arr, int num, int x, int y){
    int a = arr[num * 25 + (y * 13 + x)/8];
    return  (a >> (7 - (y * 13 + x) % 8))&1;
}

char getCharByInt(int maxI){
    if (maxI < 10) {
        char a = (char)(48 + maxI);
        return a;
    }
    else if(maxI == 31){
        return '<';
    }
    return (char)(55 + maxI);
}

void saveSmallBitmap(int* arr){
    for (int i = 0; i < 88; i++) {
//        int value = arr[2200 + i];
        int32_t *bitMap;
        bitMap = malloc(13 * 15 * sizeof(int32_t));
        for (int j = 0; j < 13; j++) {
            for (int k = 0; k < 15; k++) {
                if (getPixelByCharImage(arr, i, j, k)) {
                    bitMap[j * 15 + k] = 0xff000000;
                }
                else
                    bitMap[j * 15 + k] = 0xffffffff;
            }
        }
        CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
        CGContextRef bitmapContext=CGBitmapContextCreate(bitMap, 13, 15, 8, 4*13, colorSpace,  kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrderDefault);
        CFRelease(colorSpace);
        free(bitMap);
        CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
        CGContextRelease(bitmapContext);
        
        UIImage * newimage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
}

int getPixelByBlackImage(int32_t *arr, int x, int y){
    uint32_t tmpInt = arr[y * 88 + x / 8];
    return (tmpInt>>(7 - x % 8)) & 1;
}

void saveBitmap(int* arr){
    int32_t *bitMap;
    bitMap = malloc(131 * 700 * sizeof(int32_t));
    for (int i = 0; i < 700; i++) {
        for (int j = 0; j < 131; j++) {
            if (getPixelByBlackImage(arr, i, j) != 0) {
                bitMap[j * 700 + i] = 0xff000000;
            }
            else
                bitMap[j * 700 + i] = 0xffffffff;
        }
    }
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext=CGBitmapContextCreate(bitMap, 700, 131, 8, 4*700, colorSpace,  kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrderDefault);
    CFRelease(colorSpace);
    CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
    
    UIImage * newimage = [UIImage imageWithCGImage:cgImage];
    free(bitMap);
    CGImageRelease(cgImage);
}

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
//    [self ocr:[UIImage imageNamed:@"abc.jpg"]];
    [_captureSession startRunning];
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
    [captureOutput setAlwaysDiscardsLateVideoFrames:YES];
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInteger:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    NSDictionary *videoSetting = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSetting];
    _captureSession = [[AVCaptureSession alloc] init];
    NSString *preset = 0;
    if (!preset) {
        preset = AVCaptureSessionPresetHigh;
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
    _tipView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    UILabel *tips = [[UILabel alloc] init];
    tips.numberOfLines = 0;
    tips.font = [UIFont systemFontOfSize:15.0];
    tips.textColor = [UIColor whiteColor];
    tips.text = @"      请确保：\n\
    \u2022 证件为有效证件；\n\
    \u2022 扫描角度正对证件，无倾斜、无抖动；\n\
    \u2022 证件无反光且清晰。若灯光过暗，请打开闪光灯\n\
      或至明亮的地方扫描。\n\
    \u2022 网络顺畅";
    CGSize labelSize = [tips.text sizeWithAttributes:@{NSFontAttributeName:tips.font}];
    tips.frame = CGRectMake(0, 0, labelSize.width, labelSize.height);
    [containerView addSubview:tips];
    
    UIButton *okButton = [[UIButton alloc] initWithFrame:CGRectMake(tips.frame.origin.x + (labelSize.width - 254)/2, tips.frame.origin.y + labelSize.height + 60, 254, 44)];
    [okButton setTitle:@"知道了" forState:UIControlStateNormal];
    [okButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [okButton.titleLabel setFont:[UIFont systemFontOfSize:18.0]];
    [okButton setBackgroundColor:[UIColor clearColor]];
    [okButton addTarget:self action:@selector(dismissTipView) forControlEvents:UIControlEventTouchUpInside];
    okButton.layer.borderWidth = 0.5f;
    okButton.layer.borderColor = [UIColor whiteColor].CGColor;
    okButton.layer.cornerRadius = 4.0f;
    [containerView addSubview:okButton];
    
    containerView.frame = CGRectMake((width - labelSize.width) / 2, (height - labelSize.height) / 2, labelSize.width, labelSize.height + okButton.frame.size.height + 60);
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
    CGRect rectangleRect = CGRectZero;
    for (CIFeature *feature in rectangleFeatures) {
        if ( ![feature isKindOfClass:[CIRectangleFeature class]]) {
            continue;
        }

        CIVector *cropRect = [CIVector vectorWithCGRect:feature.bounds];
        CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
        [cropFilter setValue:ciimage forKey:@"inputImage"];
        [cropFilter setValue:cropRect forKey:@"inputRectangle"];
        croppedRecImage = [cropFilter valueForKey:@"outputImage"];
        rectangleRect = feature.bounds;
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
//                [self ocr:tmpImage];
                
                CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                CVPixelBufferLockBaseAddress(imageBuffer, 0);
                void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
//                size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
                size_t width = CVPixelBufferGetWidth(imageBuffer);
                size_t height = CVPixelBufferGetHeight(imageBuffer);
                size_t size = CVPixelBufferGetDataSize(imageBuffer);
                int8_t *byteMap = malloc(size * sizeof(int8_t) - 16);
                memcpy(byteMap, baseAddress+16, size);
                NSData *data = [NSData dataWithBytes:baseAddress length:size-16];
                CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
                
                UIImage *tttImage = [UIImage imageWithCGImage:[[CIContext contextWithOptions:nil] createCGImage:ciimage fromRect:ciimage.extent]];

                [self tmpOCR:byteMap bounds:rectangleRect width:(int)width height:(int)height image:(UIImage*)tttImage];
            }
        }
    }
    
}

- (void)ocr:(UIImage *)image{
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"bbb" ofType:@""];
//    NSData *tmpData = [NSData dataWithContentsOfFile:path];
    NSData *tmpData = (NSData *)CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage)));
    _bitMap = malloc([tmpData length] * sizeof(char));
    memcpy(_bitMap, [tmpData bytes], [tmpData length]);
    
    CGImageRef inputeCGImage = [image CGImage];
    int pixelWidth = (int)CGImageGetWidth(image.CGImage);//image.size.width * [UIScreen mainScreen].scale;
    int pixelHeight = (int)CGImageGetHeight(image.CGImage);//image.size.height * [UIScreen mainScreen].scale;
    UInt32 *pixels;
    pixels = calloc(pixelWidth*pixelHeight, sizeof(UInt32));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, pixelWidth, pixelHeight, 8, 4 * pixelWidth, colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, pixelWidth, pixelHeight), inputeCGImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);

    CGRect clippedRect  = CGRectMake(0, image.size.height - image.size.width * 0.158, image.size.width, image.size.width * 0.158);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], clippedRect);
    UIImage *newImage   = [UIImage imageWithCGImage:imageRef];//[UIImage imageWithData:tmpData];//
    CGImageRelease(imageRef);
        char *result = LibScanPassport_test(pixels, pixelWidth, pixelHeight, 0, image.size.height - image.size.width * 0.158, image.size.width, image.size.width * 0.158); //0.158 = 1/6.33
//    char *result = LibScanPassport_scanByte(tmpMap, 1280, 720, 305, 480, 669, 99); //0.158 = 1/6.33
    NSString *number = [NSString stringWithUTF8String:result];
    if (![number  isEqual: @"0"]) {
        NSLog(@"Right");
    }
    NSLog(@"%@",number);
//    free(tmpMap);
    free(pixels);
    free(_bitMap);

//    NSString *path = [[NSBundle mainBundle] pathForResource:@"bbb" ofType:@""];
//    NSData *tmpData = [NSData dataWithContentsOfFile:path];
//    _bitMap = malloc([tmpData length] * sizeof(char));
//    memcpy(_bitMap, [tmpData bytes], [tmpData length]);
//    char *result = LibScanPassport_scanByte(_bitMap, 1280, 720, 305, 480, 669, 99); //0.158 = 1/6.33
//    NSString *number = [NSString stringWithUTF8String:result];
//    if (![number  isEqual: @"0"]) {
//        NSLog(@"Right");
//    }
//    NSLog(@"%@",number);
//    //    free(tmpMap);
//    //    free(pixels);
//    free(_bitMap);

}

-(void)tmpOCR:(int8_t *)YUVData bounds:(CGRect)bounds width:(int)width height:(int)height image:(UIImage*)image{
    CGRect croppedRect  = CGRectMake(bounds.origin.x, bounds.origin.y + bounds.size.height - bounds.size.width * 0.158, bounds.size.width, bounds.size.width * 0.158);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], croppedRect);
    UIImage *newImage   = [UIImage imageWithCGImage:imageRef];//[UIImage imageWithData:tmpData];//
    CGImageRelease(imageRef);

    char *result = LibScanPassport_test(YUVData, width, height, croppedRect.origin.x, croppedRect.origin.y, croppedRect.size.width, croppedRect.size.height); //0.158 = 1/6.33

    NSString *number = [NSString stringWithUTF8String:result];
    if (![number  isEqual: @"8"]) {
        NSLog(@"Right");
    }
    NSLog(@"%@",number);
    //    free(tmpMap);
    free(YUVData);
//    free(_bitMap);

}

@end
