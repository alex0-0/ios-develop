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

- (void)CTPassportScannerDidFinish:(PassportScanResult*)scanResult;

@end

@interface OverlayViewController : UIViewController

@property (strong, nonatomic) id<PassportScannerDelegate> delegate;

@end