//
//  UIImage+TLCamera.h
//  TLCamera
//
//  Created by Will on 2021/3/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (TLCamera)

+ (UIImage *)tl_imageWithNamed:(NSString *)name;

- (UIImage *)tl_fixOrientation;

@end

NS_ASSUME_NONNULL_END
