//
//  OverlayViewController.h
//  OCRDemo
//
//  Created by ltp on 6/14/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraOverlay.h"

@interface OverlayViewController : UIViewController

@property (strong, nonatomic) CameraOverlay *overlay;
@property (assign, nonatomic) doBlock dismissImagePicker;

@end
