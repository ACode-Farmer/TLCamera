//
//  TLGPUImageController.h
//  TLCamera
//
//  Created by Will on 2021/3/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLGPUImageController : UIViewController

///完成回调，如果拍照则videoUrl为nil，如果视频则image为nil
@property (nonatomic, copy) void (^TLDoneBlock)(UIImage *image, NSURL *videoUrl);

@end

NS_ASSUME_NONNULL_END
