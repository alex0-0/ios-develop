//
//  CameraOverlay.h
//  OCRDemo
//
//  Created by ltp on 6/12/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^doBlock) (void);

@interface CameraOverlay : UIView

@property (copy, nonatomic) doBlock dismissImagePicker;
@property (copy, nonatomic) doBlock tapFlashLight;
@property (copy, nonatomic) doBlock tapTip;
@property (assign, nonatomic) CGRect idStringRect;
@property (assign, nonatomic) CGRect passportRect;

@end
