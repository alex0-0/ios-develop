//
//  OverlayViewController.h
//  OCRDemo
//
//  Created by ltp on 6/14/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScanResult.h"

@protocol PassportScannerDelegate <NSObject>

@optional
//model as parameter
- (void)PassportScannerDidFinish:(PassportScanResult*)scanResult;

@end

@protocol IDCardScannerDelegate <NSObject>

@optional
- (void)IDCardScannerDidFinish:(IDCardScanResult*)scanResult;

@end

typedef enum {
    PassportScanner,
    IDCardScanner
} ScannerType;

@interface ScannerController : UIViewController

@property (strong, nonatomic) id<PassportScannerDelegate> passportDelegate;

@property (strong, nonatomic) id<IDCardScannerDelegate> IDCardDelegate;

/**
 **  ATTENTION: please set the desired scannerType before present view controller, otherwise the scanner controller will use default type, i.e., idCardScanner, for now.
 **/
@property ScannerType scannerType;

@end