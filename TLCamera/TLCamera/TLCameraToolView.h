//
//  TLCameraToolView.h
//  TLCamera
//
//  Created by Will on 2021/3/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TLCameraToolView;
@protocol TLCameraToolViewDelegate <NSObject>

- (void)cameraToolViewDidTakePhoto:(TLCameraToolView *)toolView completion:(void (^)(BOOL success))completion;

- (void)cameraToolViewStartRecord:(TLCameraToolView *)toolView;

- (void)cameraToolViewFinishRecord:(TLCameraToolView *)toolView;

- (void)cameraToolViewClickCancel:(TLCameraToolView *)toolView;

- (void)cameraToolViewClickDone:(TLCameraToolView *)toolView;

- (void)cameraToolViewClickDismiss:(TLCameraToolView *)toolView;

@end

@interface TLCameraToolView : UIView

///
@property (nonatomic, weak ) id<TLCameraToolViewDelegate> delegate;

@property (nonatomic, assign) BOOL allowTakePhoto;

@property (nonatomic, assign) BOOL allowRecordVideo;

@property (nonatomic, assign) NSInteger maxRecordDuration;

@property (nonatomic, strong) UIColor *progressColor;

///拍照
- (void)takePhoto;

///开始动画
- (void)startAnimating;

///停止动画
- (void)stopAnimating;

@end

@interface TLCameraAlertView : UIView

///
@property (nonatomic, copy  ) void(^actionSheetBlock)(void);

+ (id)showWithTitle:(NSString *)title handler:(void (^)(void))actionSheetBlock;

@end

NS_ASSUME_NONNULL_END
