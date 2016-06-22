//
//  PassportScanResult.h
//  OCRDemo
//
//  Created by ltp on 6/22/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PassportScanResult : NSData

@property (strong, nonatomic) NSString *givenName;  //名
@property (strong, nonatomic) NSString *familyName; //姓
@property (strong, nonatomic) NSString *passportID;
@property (strong, nonatomic) NSString *nation;
@property (strong, nonatomic) NSDate *birthday;
//@property (assign, nonatomic) NSUInteger birthYear;
//@property (assign, nonatomic) NSUInteger birthMonth;
//@property (assign, nonatomic) NSUInteger birthDay;
@property (assign, nonatomic) NSInteger gender; //0 for female, 1 for male
@property (assign, nonatomic) BOOL gotLegalData;     //judge if information extracted from the init string is legal

- (PassportScanResult*)initWithScanResult:(NSString *)scanResult;

@end
