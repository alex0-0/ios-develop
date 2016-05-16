//
//  ViewController.m
//  IDRecognitionDemo
//
//  Created by alex on 16/4/16.
//  Copyright © 2016年 ctrip. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImageView *picView;
@end

@implementation ViewController {
    G8Tesseract *_tesseract;
    NSString *_recognizedText;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo {
    self.image = image;
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
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 400, 100, 100)];
    btn.backgroundColor = [UIColor blackColor];
    [btn addTarget:self action:@selector(pickImage) forControlEvents:UIControlEventTouchUpInside];
    btn.layer.cornerRadius = 50;
    self.picView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 150, 200, 200)];
    [self.view addSubview:btn];
    [self.view addSubview:self.picView];
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
