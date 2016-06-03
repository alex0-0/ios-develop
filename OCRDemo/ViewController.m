//
//  ViewController.m
//  IDRecognitionDemo
//
//  Created by alex on 16/4/16.
//  Copyright © 2016年 ctrip. All rights reserved.
//

#import "ViewController.h"
#import <TesseractOCR/TesseractOCR.h>
#import "CardIO.h"
#import "CardIOUtilities.h"
#import "OCRManager.h"

#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height
#define kButtonRadius 50
#define kPicSideLength [[UIScreen mainScreen] bounds].size.width/2

static inline UIImageView *demoImageView (UIImage *pic, NSInteger index) {
    UIImageView *ret = [[UIImageView alloc] initWithImage:pic];
    int y = index / 2 * kPicSideLength;
    int x = index % 2 * kPicSideLength;
    ret.frame = CGRectMake(x , y, kPicSideLength, kPicSideLength);
    return ret;
}

@interface ViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate, G8TesseractDelegate>

@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImageView *picView;
@property (strong, nonatomic) UIImageView *greyView;
@property (strong, nonatomic) UIImageView *blackView;
@end

@implementation ViewController {
    G8Tesseract *_tesseract;
    NSString *_recognizedText;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([CardIOUtilities canReadCardWithCamera]) {
        
    }
    
    [self initView];
    [self setupImagePicker];
    [self configTesseract];
}

-(void) pickImage{
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"ID Number" message:_recognizedText preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    self.image = [info objectForKey:UIImagePickerControllerLivePhoto];
    _tesseract.image = [self.image g8_blackAndWhite];
    [self.picView setImage:_tesseract.image];
    _tesseract.rect = CGRectMake(0, 0, _tesseract.image.size.width, _tesseract.image.size.height);
    if ([_tesseract recognize]) {
        _recognizedText = [_tesseract recognizedText];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}

-(void)initView {
    self.navigationController.navigationBarHidden = YES;
    [self.view setBackgroundColor:[UIColor purpleColor]];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth/2 - kButtonRadius, kScreenHeight - kButtonRadius * 2, kButtonRadius * 2, kButtonRadius * 2)];
    btn.backgroundColor = [UIColor blackColor];
    [btn addTarget:self action:@selector(pickImage) forControlEvents:UIControlEventTouchUpInside];
    btn.layer.cornerRadius = kButtonRadius;
    [self.view addSubview:btn];
    
    _image = [UIImage imageNamed:@"passport_0.jpg"];
    self.picView = demoImageView(_image, 0);
    [self.view addSubview:self.picView];
    
    OCRManager *ocrManager = [[OCRManager alloc] init];
    UIImage *greyImg = [ocrManager getGreyScaleImage:_image];
    _greyView = demoImageView(greyImg, 1);
    [self.view addSubview:_greyView];
    UIImage *blackImg = [ocrManager getBlackImage:greyImg];
    _blackView = demoImageView(blackImg, 2);
    [self.view addSubview:_blackView];
    
    
}

-(void)setupImagePicker {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePicker = [[UIImagePickerController alloc] init];
        //        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        //        self.imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        self.imagePicker.allowsEditing = NO;
        self.imagePicker.delegate = self;
    }
}

-(void)configTesseract {
    _tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    _tesseract.delegate = self;
    _tesseract.charWhitelist = @"0123456789";
    _tesseract.maximumRecognitionTime = 5.0;
}

#pragma mark  ---- tesseract delegate ----
- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    return NO;
}

@end
