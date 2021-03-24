//
//  TLGPUImageController.m
//  TLCamera
//
//  Created by Will on 2021/3/23.
//

#import "TLGPUImageController.h"
#import <CoreMotion/CoreMotion.h>
#import "TLDefine.h"
#import "TLPlayer.h"
#import "TLCameraToolView.h"
#import "GPUImage.h"

@interface TLGPUImageController ()<GPUImageVideoCameraDelegate,TLCameraToolViewDelegate>
{
    BOOL _didLayoutSubviews;
    BOOL _cameraUnavailable;
    BOOL _accessUnavailable;
}

//操作工具视图
@property (nonatomic, strong) TLCameraToolView *toolView;

//切换摄像头按钮
@property (nonatomic, strong) UIButton *switchButton;
//聚焦视图
@property (nonatomic, strong) UIImageView *focusCursorImageView;
//录制视频保存的url
@property (nonatomic, strong) NSURL *videoUrl;
//预览照片显示
@property (nonatomic, strong) UIImageView *previewImageView;
//播放视频
@property (nonatomic, strong) TLPlayer *playerView;
///模糊视图
@property (nonatomic, strong) UIImageView *blurview;

//监听
@property (nonatomic, strong) CMMotionManager *motionManager;
//图片/视频方向
@property (nonatomic, assign) AVCaptureVideoOrientation orientation;

///输入
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
///滤镜
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;
///显示
@property (nonatomic, strong) GPUImageView *filterView;
///写入视频
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;

///
@property (nonatomic, strong) UIButton *filterBtn1;
///
@property (nonatomic, strong) UIButton *filterBtn2;

@end

@implementation TLGPUImageController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self gc_setupUI];
    
    [self gc_setupGPUImage];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (_didLayoutSubviews) return;
    _didLayoutSubviews = YES;
    
    CGFloat areaBottom = 0;
    if (@available(iOS 11.0, *)) {
        areaBottom = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    }
    self.toolView.frame = CGRectMake(0, self.view.tl_height - 150 - areaBottom, self.view.tl_width, 100);
    self.switchButton.frame = CGRectMake(self.view.tl_width - 50, UIApplication.sharedApplication.statusBarFrame.size.height + 20, 30, 30);
    
    self.filterBtn1.frame = CGRectMake(self.view.tl_width - 70, 200, 60, 40);
    self.filterBtn2.frame = CGRectMake(self.view.tl_width - 70, 260, 60, 40);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [UIApplication sharedApplication].statusBarHidden = YES;
#pragma clang diagnostic pop
    
    if (self.blurview) {
        //durantion = 0.3,其实最好是能监听到摄像头有画面需要的时间，但是没找到回调
        [UIView animateWithDuration:0.38 animations:^{
            self.blurview.alpha = 0;
        } completion:^(BOOL finished) {
            [self.blurview removeFromSuperview];
            self.blurview = nil;
        }];
    }
    
    [self.videoCamera startCameraCapture];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [UIApplication sharedApplication].statusBarHidden = NO;
#pragma clang diagnostic pop
    
    if (self.motionManager) {
        [self.motionManager stopDeviceMotionUpdates];
        self.motionManager = nil;
    }
}

- (void)dealloc {
    NSLog(@"%@ dealloc",self.class);
    
    if (self.videoCamera.isRunning) {
        [self.videoCamera stopCameraCapture];
    }
    [self.videoCamera removeAllTargets];
    [GPUImageContext.sharedImageProcessingContext.framebufferCache purgeAllUnassignedFramebuffers];
}

- (void)gc_setupGPUImage {
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.delegate = self;
    self.videoCamera.outputImageOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    self.filter = [[GPUImageSepiaFilter alloc] init];
    
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:self.filterView atIndex:0];
    
    [self.videoCamera addTarget:self.filter];
    [self.filter addTarget:self.filterView];
}

- (void)gc_setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    //高斯模糊
    self.blurview = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.blurview.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];
    UIVisualEffectView *effectview = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    effectview.frame = self.blurview.bounds;
    [self.blurview addSubview:effectview];
    [self.view addSubview:self.blurview];
    
    self.toolView = [[TLCameraToolView alloc] init];
    self.toolView.userInteractionEnabled = NO;
    self.toolView.delegate = self;
    self.toolView.allowTakePhoto = YES;
    self.toolView.allowRecordVideo = YES;
    self.toolView.progressColor = kColorRGB(80, 170, 56);
    self.toolView.maxRecordDuration = 15;
    [self.view addSubview:self.toolView];
    
    self.focusCursorImageView = [[UIImageView alloc] initWithImage:[UIImage tl_imageWithNamed:@"tl_focus_icon"]];
    self.focusCursorImageView.frame = CGRectMake(0, 0, 45, 45);
    self.focusCursorImageView.alpha = 0;
    [self.view addSubview:self.focusCursorImageView];
    
    self.switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.switchButton setImage:[UIImage tl_imageWithNamed:@"tl_switch_camera"] forState:UIControlStateNormal];
    [self.switchButton addTarget:self action:@selector(exchangeCameraPosition) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.switchButton];
    [kColorRGB(244, 244, 244) colorWithAlphaComponent:0.9];
    
    _filterBtn1 = [UIButton buttonWithType:UIButtonTypeCustom];
    _filterBtn1.backgroundColor = [kColorRGB(244, 244, 244) colorWithAlphaComponent:0.7];
    _filterBtn1.layer.cornerRadius = 6.0;
    [_filterBtn1 setTitle:@"滤镜1" forState:0];
    _filterBtn1.titleLabel.font = [UIFont systemFontOfSize:14];
    [_filterBtn1 setTitleColor:UIColor.blackColor forState:0];
    [_filterBtn1 setTitleColor:UIColor.orangeColor forState:UIControlStateSelected];
    [_filterBtn1 addTarget:self action:@selector(filterBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    _filterBtn1.selected = YES;
    
    _filterBtn2 = [UIButton buttonWithType:UIButtonTypeCustom];
    _filterBtn2.backgroundColor = [kColorRGB(244, 244, 244) colorWithAlphaComponent:0.7];
    _filterBtn2.layer.cornerRadius = 6.0;
    [_filterBtn2 setTitle:@"滤镜2" forState:0];
    _filterBtn2.titleLabel.font = [UIFont systemFontOfSize:14];
    [_filterBtn2 setTitleColor:UIColor.blackColor forState:0];
    [_filterBtn2 setTitleColor:UIColor.orangeColor forState:UIControlStateSelected];
    [_filterBtn2 addTarget:self action:@selector(filterBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_filterBtn1];
    [self.view addSubview:_filterBtn2];
    
    //
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(adjustFocusPoint:)];
    [self.view addGestureRecognizer:singleTap];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exchangeCameraPosition)];
    doubleTap.numberOfTapsRequired = 2;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:doubleTap];
}

- (void)filterBtnAction:(UIButton *)sender {
    if (sender.isSelected) return;
    
    _filterBtn1.selected = _filterBtn2.selected = NO;
    sender.selected = YES;
    //GPUImageSketchFilter GPUImageSepiaFilter
    [self.videoCamera stopCameraCapture];
    [self.filter removeAllTargets];
    [self.videoCamera removeAllTargets];
    if (sender == _filterBtn1) {
        self.filter = [[GPUImageSepiaFilter alloc] init];
    }
    else {
        self.filter = [[GPUImageSketchFilter alloc] init];
    }
    [self.videoCamera addTarget:self.filter];
    [self.filter addTarget:self.filterView];
    [self.videoCamera startCameraCapture];
}

#pragma mark - 手势
- (void)adjustFocusPoint:(UITapGestureRecognizer *)singleTap {
    
}

- (void)exchangeCameraPosition {
    self.switchButton.enabled = NO;
    
    AVCaptureDevicePosition position = [self.videoCamera cameraPosition];
    if (position == AVCaptureDevicePositionBack) {
        position = AVCaptureDevicePositionFront;
    }
    else {
        position = AVCaptureDevicePositionBack;
    }
    [self.videoCamera stopCameraCapture];
    [self.filter removeAllTargets];
    [self.videoCamera removeAllTargets];
    
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:position];
    self.videoCamera.delegate = self;
    self.videoCamera.outputImageOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    [self.videoCamera addTarget:self.filter];
    [self.filter addTarget:self.filterView];
    [self.videoCamera startCameraCapture];
    
    self.switchButton.enabled = YES;
}

- (void)playVideo {
    dispatch_main_async_safe(^{
        if (!self->_playerView) {
            self.playerView = [[TLPlayer alloc] initWithFrame:self.view.bounds];
            [self.view insertSubview:self.playerView belowSubview:self.toolView];
        }
        self.playerView.hidden = NO;
        self.playerView.videoUrl = self.videoUrl;
        [self.playerView play];
    });
}

- (void)deleteVideo {
    if (self.videoUrl) {
        [self.playerView reset];
        [UIView animateWithDuration:0.25 animations:^{
            self.playerView.alpha = 0;
        } completion:^(BOOL finished) {
            self.playerView.hidden = YES;
            self.playerView.alpha = 1;
        }];
        [[NSFileManager defaultManager] removeItemAtURL:self.videoUrl error:nil];
        self.videoUrl = nil;
    }
}

//设置焦距
- (void)setVideoZoomFactor:(CGFloat)zoomFactor {
    /**
     iPhone8:minAvailableVideoZoomFactor = 1 maxAvailableVideoZoomFactor = 135
     */
    zoomFactor = MAX(zoomFactor, 1);
    
    AVCaptureDevice *device = [self.videoCamera inputCamera];
    NSError *error = nil;
    //改变设备属性前一定要先调用lockForConfiguration:，之后使用unlockForConfiguration解锁
    if (![device lockForConfiguration:&error]) {
        return;
    }
    device.videoZoomFactor = zoomFactor;
    [device unlockForConfiguration];
}

#pragma mark - TLCameraToolViewDelegate
- (void)cameraToolViewDidTakePhoto:(TLCameraToolView *)toolView completion:(void (^)(BOOL success))completion {
    if (!_previewImageView) {
        _previewImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _previewImageView.backgroundColor = [UIColor blackColor];
        _previewImageView.hidden = YES;
        _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view insertSubview:_previewImageView belowSubview:self.toolView];
    }
    [self.filter useNextFrameForImageCapture];
    UIImage *image = [self.filter imageFromCurrentFramebuffer];
    if (image == nil) {
        completion(NO);
        return;;
    }
    completion(YES);
    self.previewImageView.hidden = NO;
    self.previewImageView.image = [image tl_fixOrientation];
    [self.videoCamera stopCameraCapture];
}

- (void)cameraToolViewStartRecord:(TLCameraToolView *)toolView {
    NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingFormat:@"TLCameraVideo.%@",@"mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    }
    self.videoUrl = [NSURL fileURLWithPath:outputFilePath];
    
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.videoUrl size:self.filterView.sizeInPixels];
    self.movieWriter.encodingLiveVideo = YES;
    [self.filter addTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = self.movieWriter;
    [self.movieWriter startRecording];
    
    [self.toolView startAnimating];
}

- (void)cameraToolViewFinishRecord:(TLCameraToolView *)toolView {
    [self.filter removeTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = nil;
    __weak typeof(self) weakSelf = self;
    [self.movieWriter finishRecordingWithCompletionHandler:^{
        //__strong typeof(weakSelf) strongSelf = weakSelf;
        [weakSelf playVideo];
    }];
    [self.videoCamera stopCameraCapture];
    
    [self setVideoZoomFactor:1];
}

- (void)cameraToolViewClickCancel:(TLCameraToolView *)toolView {
    [self.videoCamera startCameraCapture];
    
    if (self.previewImageView.image != nil) {
        [UIView animateWithDuration:0.25 animations:^{
            self.previewImageView.alpha = 0;
        } completion:^(BOOL finished) {
            self.previewImageView.hidden = YES;
            self.previewImageView.alpha = 1;
            self.previewImageView.image = nil;
        }];
    }
    
    [self deleteVideo];
}

- (void)cameraToolViewClickDone:(TLCameraToolView *)toolView {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraToolViewClickDismiss:(TLCameraToolView *)toolView {
    [self.videoCamera stopCameraCapture];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraToolViewClickDismiss:(TLCameraToolView *)toolView setVideoZoomFactor:(CGFloat)zoomFactor {
    [self setVideoZoomFactor:zoomFactor];
}

#pragma mark - GPUImageVideoCameraDelegate
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    //NSLog(@"willOutputSampleBuffer");
    
    dispatch_main_async_safe(^{
        if (!self.toolView.isUserInteractionEnabled) {
            self.toolView.userInteractionEnabled = YES;
        }
    });
}

#pragma mark - Getters
- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
