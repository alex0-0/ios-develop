//
//  OverlayViewController.m
//  OCRDemo
//
//  Created by ltp on 6/14/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "ScannerController.h"
#import <AVFoundation/AVFoundation.h>
#import "LibScanPassport.h"
#import "LibScanIDCard.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)

static NSMutableArray<LetterPosition*> *letterPosArray;

//get position of 88 letters
void saveLetterPos(int *pos){
    NSLock *arrayLock = [[NSLock alloc] init];
    [arrayLock lock];
    
    if (letterPosArray) {
        [letterPosArray removeAllObjects];
    }
    else {
        letterPosArray = [NSMutableArray array];
    }
    for (int i = 0; i < 88; i++) {
        LetterPosition *tmpLetterPos = [[LetterPosition alloc] init];
        if (IS_IPHONE_4_OR_LESS && !SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            //in iphone4 with ios7, the picture is not cropped correctly
            tmpLetterPos.x = pos[i * 4] - 50;
        }
        else
            tmpLetterPos.x = pos[i * 4] - 30;
        tmpLetterPos.y = pos[i * 4 + 1];
        if (IS_IPHONE_4_OR_LESS && !SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            tmpLetterPos.toX = pos[i * 4 + 2] - 40;
        }
        else
            tmpLetterPos.toX = pos[i * 4 + 2] - 20;
        tmpLetterPos.toY = pos[i * 4 + 3];
        [letterPosArray addObject:tmpLetterPos];
    }
    //release memory
    free(pos);
    [arrayLock unlock];
}
//
//int getPixelByCharImage(int *arr, int num, int x, int y){
//    int a = arr[num * 25 + (y * 13 + x)/8];
//    return  (a >> (7 - (y * 13 + x) % 8))&1;
//}
//
//char getCharByInt(int maxI){
//    if (maxI < 10) {
//        char a = (char)(48 + maxI);
//        return a;
//    }
//    else if(maxI == 31){
//        return '<';
//    }
//    return (char)(55 + maxI);
//}
//
//void saveSmallBitmap(int* arr){
//    for (int i = 0; i < 88; i++) {
////        int value = arr[2200 + i];
//        int32_t *bitMap;
//        bitMap = malloc(13 * 15 * sizeof(int32_t));
//        for (int j = 0; j < 13; j++) {
//            for (int k = 0; k < 15; k++) {
//                if (getPixelByCharImage(arr, i, j, k)) {
//                    bitMap[j * 15 + k] = 0xff000000;
//                }
//                else
//                    bitMap[j * 15 + k] = 0xffffffff;
//            }
//        }
//        CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
//        CGContextRef bitmapContext=CGBitmapContextCreate(bitMap, 13, 15, 8, 4*13, colorSpace,  kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrderDefault);
//        CFRelease(colorSpace);
//        free(bitMap);
//        CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
//        CGContextRelease(bitmapContext);
//        
//        UIImage *newimage = [UIImage imageWithCGImage:cgImage];
//        CGImageRelease(cgImage);
//        free(bitMap);
//    }
//}
//
//int getPixelByBlackImage(int32_t *arr, int x, int y){
//    uint32_t tmpInt = arr[y * 88 + x / 8];
//    return (tmpInt>>(7 - x % 8)) & 1;
//}
//
//void saveBitmap(int* arr){
//    int32_t *bitMap;
//    bitMap = malloc(131 * 700 * sizeof(int32_t));
//    for (int i = 0; i < 700; i++) {
//        for (int j = 0; j < 131; j++) {
//            if (getPixelByBlackImage(arr, i, j) != 0) {
//                bitMap[j * 700 + i] = 0xff000000;
//            }
//            else
//                bitMap[j * 700 + i] = 0xffffffff;
//        }
//    }
//    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
//    CGContextRef bitmapContext=CGBitmapContextCreate(bitMap, 700, 131, 8, 4*700, colorSpace,  kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrderDefault);
//    CFRelease(colorSpace);
//    CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
//    CGContextRelease(bitmapContext);
//    
//    UIImage *newimage = [UIImage imageWithCGImage:cgImage];
//    free(bitMap);
//    CGImageRelease(cgImage);
//}

@interface ScannerController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong, nonatomic) PassportScanResult *resultModel;
@end

@implementation ScannerController{
    UIView *_tipView;
    CameraOverlay *_passportOverlay;
    CameraOverlay *_idCardOverlay;
    AVCaptureSession *_captureSession;
    AVCaptureVideoPreviewLayer *_previewLayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initCapture];
    [self initOverlayView];
    [self initTipView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:true];
    switch (_scannerType) {
        case PassportScanner:{
            if ([_idCardOverlay superview]) {
                [_idCardOverlay removeFromSuperview];
            }
            [self.view addSubview:_passportOverlay];
        }
            break;
        case IDCardScanner:{
            if ([_passportOverlay superview]) {
                [_passportOverlay removeFromSuperview];
            }
            [self.view addSubview:_idCardOverlay];
        }
        default:
            break;
    }
    static BOOL firstTime = TRUE;   //only automaticall show if the app enters for the first time
    if (firstTime) {
        [self.view addSubview:_tipView];
        firstTime = NO;
    }
    [_captureSession startRunning];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)initObServer{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleError:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVCaptureSessionWasInterruptedNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:nil];
//}

- (void)initCapture{
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    if (!captureInput) {
        return;
    }
    AVCaptureDeviceFormat *bestFormat = nil;
    AVFrameRateRange *bestFrameRateRange = nil;
    for (AVCaptureDeviceFormat *format in [captureDevice formats]) {
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            if (!bestFrameRateRange) {
                bestFrameRateRange = range;
                bestFormat = format;
            }
            if (range.minFrameRate < bestFrameRateRange.minFrameRate) {
                bestFormat = format;
                bestFrameRateRange = range;
            }
        }
    }
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = true;
    dispatch_queue_t sessionQueue = dispatch_queue_create("cameraQueue", NULL);
    _captureSession = [[AVCaptureSession alloc] init];
    
    [_captureSession beginConfiguration];
    if (bestFormat) {
        if ([captureDevice lockForConfiguration:nil] == YES) {
            captureDevice.activeFormat = bestFormat;
            captureDevice.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
            captureDevice.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
            [captureDevice unlockForConfiguration];
        }
    }
    [captureOutput setSampleBufferDelegate:self queue:sessionQueue];
    [captureOutput setAlwaysDiscardsLateVideoFrames:YES];
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInteger:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    NSDictionary *videoSetting = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSetting];
    NSString *preset = 0;
    if (!preset) {
        if ([captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPresetHigh]) {
            preset = AVCaptureSessionPresetHigh;
        }
        else
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
    
    [_captureSession commitConfiguration];
    if (!_scannerType) {
        _scannerType = IDCardScanner;
    }
}

- (void)initTipView{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat width = screenSize.width;
    CGFloat height = screenSize.height;
    UIView *containerView = [[UIView alloc] init];
    
    _tipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        _tipView.backgroundColor = [UIColor clearColor];
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = _tipView.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_tipView addSubview:blurEffectView];
    }
    else {
        _tipView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    }
    UILabel *tips = [[UILabel alloc] init];
    tips.numberOfLines = 0;
    tips.font = [UIFont systemFontOfSize:15.0];
    tips.textColor = [UIColor whiteColor];
    tips.text = @"      请确保：\n\n\
    \u2022 证件为有效证件（暂仅支持中国大陆护照）\n\n\
    \u2022 扫描角度正对证件，无倾斜、无抖动\n\n\
    \u2022 证件无反光且清晰。若灯光过暗，请打开闪光灯\n\n\
    或至明亮的地方扫描\n\n\
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
    
    [containerView setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    containerView.frame = CGRectMake((width - labelSize.height - 60 - okButton.frame.size.height) / 2, (height - labelSize.width) / 2, labelSize.height + okButton.frame.size.height + 60, MAX(labelSize.width, okButton.frame.size.width));
    [_tipView addSubview:containerView];
}

- (void)initOverlayView{
    _passportOverlay = [[CameraOverlay alloc] init:CameraOverlayTypePassport];
    _passportOverlay.frame = [UIScreen mainScreen].bounds;
    __weak typeof(self) weakSelf = self;
    _passportOverlay.tapFlashLight = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self flashLight];
    };
    _passportOverlay.dismissImagePicker = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self back];
    };
    _passportOverlay.tapTip = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self showTip];
    };
    _idCardOverlay = [[CameraOverlay alloc] init:CameraOverlayTypeIDCard];
    _idCardOverlay.frame = [UIScreen mainScreen].bounds;
    _idCardOverlay.tapFlashLight = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self flashLight];
    };
    _idCardOverlay.dismissImagePicker = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self back];
    };
    _idCardOverlay.tapTip = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self showTip];
    };

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
    if ([_captureSession isRunning]) {
        [_captureSession stopRunning];
    }
    if ([self presentingViewController] != nil) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)showTip{
    [self.view addSubview:_tipView];
}

#pragma mark -------------AVCaptureVideoDataOutputSampleBufferDelegate   -------------------

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    @autoreleasepool {
        CIImage *ciimage = [CIImage imageWithCVPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
        CIImage *croppedRecImage = nil;
        CGRect rectangleRect = CGRectZero;
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            
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
                rectangleRect = feature.bounds;
            }
        }
        else {//for system version less than 8.0, there is no rectangle detector, so the cropped rect need to be fixed.
            croppedRecImage = ciimage;
            CGSize imageSize = ciimage.extent.size;
            float scaleRatio = imageSize.height / 320;
            switch (_scannerType) {
                case IDCardScanner:{
                    ;
                }
                    break;
                case PassportScanner:{
                    CGRect passportRect = CGRectMake((imageSize.width - 354 * scaleRatio) / 2, (imageSize.height - 249 * scaleRatio) / 2, 354 * scaleRatio, 249 * scaleRatio);
                    rectangleRect = passportRect;
                }
                default:
                    break;
            }
        }
        if (croppedRecImage) {
            BOOL faceDetected = FALSE;
            CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:[CIContext contextWithOptions:nil] options:nil];
            NSArray *faceFeatures = [faceDetector featuresInImage:croppedRecImage options:nil];
            for (CIFeature *feature in faceFeatures) {
                if ( [feature isKindOfClass:[CIFaceFeature class]]) {
                    faceDetected = YES;
                    break;
                }
            }
            if (!faceDetected) {
                return;
            }
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            CVPixelBufferLockBaseAddress(imageBuffer, 0);
            void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
            //                size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
            size_t width = CVPixelBufferGetWidth(imageBuffer);
            size_t height = CVPixelBufferGetHeight(imageBuffer);
            size_t size = CVPixelBufferGetDataSize(imageBuffer);
            int8_t *byteMap = malloc(size * sizeof(int8_t) - 16);
            memcpy(byteMap, baseAddress + 16, size);
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            CGImageRef tmpImageRef = [[CIContext contextWithOptions:nil] createCGImage:ciimage fromRect:ciimage.extent];
            UIImage *wholeImage = [UIImage imageWithCGImage:tmpImageRef];
            CGImageRelease(tmpImageRef);
            
            switch (_scannerType) {
                case PassportScanner:
                    [self passportOCR:byteMap bounds:rectangleRect width:(int)width height:(int)height image:(UIImage*)wholeImage];
                    break;
                case IDCardScanner:
                    [self IDCardOCR:byteMap bounds:rectangleRect width:(int)width height:(int)height image:(UIImage*)wholeImage];
                default:
                    break;
            }
            
        }
        
    }
}

-(void)IDCardOCR:(int8_t *)YUVData bounds:(CGRect)bounds width:(int)width height:(int)height image:(UIImage*)image{
    @synchronized (self) {

    //105/330 = 0.318 (105:length of "公民身份号码"   330:length of id card)
    //55/208 = 0.264 (55:height of rect in which the id number possibly exists   208:height of id card)
    CGSize possibleSize = CGSizeMake(bounds.size.width - bounds.size.width * 0.318, bounds.size.height * 0.264);
    CGRect croppedRect  = CGRectMake(bounds.origin.x + bounds.size.width - possibleSize.width, bounds.origin.y + bounds.size.height - possibleSize.height, possibleSize.width, possibleSize.height);
//    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], croppedRect);
//    UIImage *newImage = [UIImage imageWithCGImage:imageRef];//[UIImage imageWithData:tmpData];//
//    CGImageRelease(imageRef);
    
    static int count = 0;
    printf("%d",++count);
    char *result = LibScanIDCard_scanByteIDCard(YUVData, width, height, croppedRect.origin.x, croppedRect.origin.y, croppedRect.size.width, croppedRect.size.height);
    free(YUVData);
    
    NSString *scanResult = (result)?[NSString stringWithUTF8String:result]:@"";

    if (scanResult.length >= 15) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"result"
                                                        message:scanResult
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        if ([_captureSession isRunning]) {
            [_captureSession stopRunning];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
            if ([_IDCardDelegate respondsToSelector:@selector(IDCardScannerDidFinish:)]) {
                [_IDCardDelegate IDCardScannerDidFinish:scanResult];
            }
        });
    }
    }
}

-(void)passportOCR:(int8_t *)YUVData bounds:(CGRect)bounds width:(int)width height:(int)height image:(UIImage*)image{//125*88
    @synchronized (self) {

    CGRect croppedRect  = CGRectMake(bounds.origin.x, bounds.origin.y + bounds.size.height - bounds.size.width * 0.158, bounds.size.width, bounds.size.width * 0.158);
//    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], croppedRect);
////    UIImage *newImage = [UIImage imageWithCGImage:imageRef];//[UIImage imageWithData:tmpData];//
//    CGImageRelease(imageRef);

    char *result = LibScanPassport_scanByte(YUVData, width, height, croppedRect.origin.x, croppedRect.origin.y, croppedRect.size.width, croppedRect.size.height); //0.158 = 1/6.33
    free(YUVData);
    NSString *scanResult = (result)?[NSString stringWithUTF8String:result]:@"";
    if (scanResult && scanResult.length >= 88) {
        PassportScanResult *resultModel = [[PassportScanResult alloc] initWithScanResult:scanResult];
        if (resultModel.gotLegalData) {
            if ([_captureSession isRunning]) {
                [_captureSession stopRunning];
            }
            //crop image for user to validate the information extracted from the scanning
            [resultModel cropImage:image inRect:bounds withPositions:letterPosArray];
            NSString *showResult = [NSString stringWithFormat:@"family name:\t%@\ngiven name:\t%@\npassportID:\t%@\nnation:\t%@gender:\t%@",
                                    resultModel.familyName,
                                    resultModel.givenName,
                                    resultModel.passportID,
                                    resultModel.nation,
                                    (resultModel.gender == 0)?@"女":@"男"
                                    ];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"result"
                                                            message:showResult
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
                if ([_passportDelegate respondsToSelector:@selector(PassportScannerDidFinish:)]) {
                    [_passportDelegate PassportScannerDidFinish:resultModel];
                }
            });
        }
    }
    NSLog(@"%@", scanResult);
    }
}

@end
