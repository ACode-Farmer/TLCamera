//
//  TLCameraController.h
//  TLCamera
//
//  Created by Will on 2021/1/6.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLCameraController : UIViewController

///是否允许拍照，默认YES
@property (nonatomic, assign) BOOL allowTakePhoto;
///是否允许录制视频，默认YES
@property (nonatomic, assign) BOOL allowRecordVideo;
///最大录制时长，默认15s
@property (nonatomic, assign) NSInteger maxRecordDuration;
///进度条颜色，默认kColorRGB(80, 170, 56)
@property (nonatomic, strong) UIColor *progressColor;
///视频录制分辨率，默认AVCaptureSessionPreset1280x720
@property (nonatomic, copy  ) AVCaptureSessionPreset sessionPreset;
///视频导出格式，默认mp4
@property (nonatomic, copy  ) NSString *videoType;

///完成回调，如果拍照则videoUrl为nil，如果视频则image为nil
@property (nonatomic, copy) void (^TLDoneBlock)(UIImage *image, NSURL *videoUrl);

@end

NS_ASSUME_NONNULL_END
