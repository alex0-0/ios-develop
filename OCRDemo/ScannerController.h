//
//  OverlayViewController.h
//  OCRDemo
//
//  Created by ltp on 6/14/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraOverlay.h"
#import "PassportScanResult.h"

void saveSmallBitmap(int* arr);
void saveBitmap(int* arr);
void saveLetterPos(int *pos);

@protocol PassportScannerDelegate <NSObject>

@optional
//model as parameter
- (void)PassportScannerDidFinish:(PassportScanResult*)scanResult;

@end

@protocol idCardScannerDelegate <NSObject>

@optional
//id card string as parameter
- (void)idCardScannerDidFinish:(NSString*)scanResult;

@end

typedef enum {
    PassportScanner,
    IDCardScanner
} ScannerType;

@interface ScannerController : UIViewController

@property (strong, nonatomic) id<PassportScannerDelegate> passportDelegate;

@property (strong, nonatomic) id<idCardScannerDelegate> idCardDelegate;

/**
 **  ATTENTION: please set the desired scannerType before present view controller, otherwise the scanner controller will use default type, i.e., idCardScanner, for now.
 **/
@property ScannerType scannerType;

@end