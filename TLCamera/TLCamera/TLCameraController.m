//
//  TLCameraController.m
//  TLCamera
//
//  Created by Will on 2021/1/6.
//

#import "TLCameraController.h"
#import <CoreMotion/CoreMotion.h>

#import "TLDefine.h"
#import "TLPlayer.h"
#import "TLCameraToolView.h"

@interface TLCameraController ()<TLCameraToolViewDelegate,AVCaptureFileOutputRecordingDelegate,UIGestureRecognizerDelegate>
{
    BOOL _didLayoutSubviews;
    BOOL _cameraUnavailable;
    BOOL _accessUnavailable;
}

//操作工具视图
@property (nonatomic, strong) TLCameraToolView *toolView;

//输入设备和输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureSession *session;
//设备输入流
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
//照片输出流对象
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutPut;
//视频输出流
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutPut;

//相机实时预览图层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
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

@end

@implementation TLCameraController

- (instancetype)init {
    if (self = [super init]) {
        self.allowTakePhoto = YES;
        self.allowRecordVideo = YES;
        self.maxRecordDuration = 15;
        self.progressColor = kColorRGB(80, 170, 56);
        self.sessionPreset = AVCaptureSessionPreset1280x720;
        self.videoType = @"mp4";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    //摄像头不可用状态
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        _cameraUnavailable = YES;
        return;
    }
    
    if (self.allowTakePhoto == NO && self.allowRecordVideo == NO) {
        self.allowTakePhoto = YES;
    }
    
    if ([self setupCamera]) {
        [self observeDeviceMotion];
    }
    else {
        _cameraUnavailable = YES;
    }
    
    //权限
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (!granted) {
            self->_accessUnavailable = YES;
            return;
        }
        if (self.allowRecordVideo) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (!granted) {
                    self->_accessUnavailable = YES;
                    return;
                }
            }];
        }
    }];
    
    if (self.allowRecordVideo) {
        //暂停其他音频
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
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
    self.previewLayer.frame = self.view.layer.bounds;
    self.switchButton.frame = CGRectMake(self.view.tl_width - 50, UIApplication.sharedApplication.statusBarFrame.size.height + 20, 30, 30);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [UIApplication sharedApplication].statusBarHidden = YES;
#pragma clang diagnostic pop
    
    if (_cameraUnavailable) {
        [TLCameraAlertView showWithTitle:@"相机无法使用" handler:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        return;
    }
    if (_accessUnavailable) {
        NSDictionary *infoDict = [NSBundle mainBundle].localizedInfoDictionary;
        if (!infoDict || !infoDict.count) {
            infoDict = [NSBundle mainBundle].infoDictionary;
        }
        if (!infoDict || !infoDict.count) {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
            infoDict = [NSDictionary dictionaryWithContentsOfFile:path];
        }
        NSString *appName = [infoDict valueForKey:@"CFBundleDisplayName"];
        if (!appName) appName = [infoDict valueForKey:@"CFBundleName"];
        if (!appName) appName = [infoDict valueForKey:@"CFBundleExecutable"];
        [TLCameraAlertView showWithTitle:[NSString stringWithFormat:@"请在iPhone的“设置-隐私”选项中，允许%@访问你的相机和麦克风",appName]
                                 handler:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        return;
    }
    if (self.blurview) {
        //durantion = 0.3,其实最好是能监听到摄像头有画面需要的时间，但是没找到回调
        [UIView animateWithDuration:0.38 animations:^{
            self.blurview.alpha = 0;
        } completion:^(BOOL finished) {
            [self.blurview removeFromSuperview];
            self.blurview = nil;
        }];
    }
    
    //启动
    [self.session startRunning];
    [self setFocusCursorWithPoint:self.view.center];
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (self.session) {
        [self.session stopRunning];
    }
}

- (void)dealloc {
    NSLog(@"%@ dealloc",self.class);
    if ([_session isRunning]) {
        [_session stopRunning];
    }
    
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)willResignActive {
    if ([self.session isRunning]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)playVideo {
    if (!_playerView) {
        self.playerView = [[TLPlayer alloc] initWithFrame:self.view.bounds];
        [self.view insertSubview:self.playerView belowSubview:self.toolView];
    }
    self.playerView.hidden = NO;
    self.playerView.videoUrl = self.videoUrl;
    [self.playerView play];
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
    }
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    //高斯模糊
    self.blurview = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.blurview.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];
    UIVisualEffectView *effectview = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    effectview.frame = self.blurview.bounds;
    [self.blurview addSubview:effectview];
    [self.view addSubview:self.blurview];
    
    self.toolView = [[TLCameraToolView alloc] init];
    self.toolView.delegate = self;
    self.toolView.allowTakePhoto = self.allowTakePhoto;
    self.toolView.allowRecordVideo = self.allowRecordVideo;
    self.toolView.progressColor = self.progressColor;
    self.toolView.maxRecordDuration = self.maxRecordDuration;
    [self.view addSubview:self.toolView];
    
    self.focusCursorImageView = [[UIImageView alloc] initWithImage:[UIImage tl_imageWithNamed:@"tl_focus_icon"]];
    self.focusCursorImageView.frame = CGRectMake(0, 0, 45, 45);
    self.focusCursorImageView.alpha = 0;
    [self.view addSubview:self.focusCursorImageView];
    
    self.switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.switchButton setImage:[UIImage tl_imageWithNamed:@"tl_switch_camera"] forState:UIControlStateNormal];
    [self.switchButton addTarget:self action:@selector(exchangeCameraPosition) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.switchButton];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(adjustFocusPoint:)];
    [self.view addGestureRecognizer:singleTap];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exchangeCameraPosition)];
    doubleTap.numberOfTapsRequired = 2;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:doubleTap];
    
//    if (self.allowRecordVideo) {
//        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(adjustCameraFocus:)];
//        pan.maximumNumberOfTouches = 1;
//        [self.view addGestureRecognizer:pan];
//    }
}

#pragma mark - 初始化相机
- (BOOL)setupCamera {
    self.session = [[AVCaptureSession alloc] init];
    
    //优先使用后置摄像头
    AVCaptureDevice *captureDevice = [self backCamera];
    if (captureDevice == nil) {
        captureDevice = [self frontCamera];
    }
    if (captureDevice == nil) {
        return NO;
    }
    //设备输入流
    self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    
    //图片输出流
    self.imageOutPut = [[AVCaptureStillImageOutput alloc] init];
    //设置输出图片格式（JPEG）
    NSDictionary *dicOutputSetting = [NSDictionary dictionaryWithObject:AVVideoCodecJPEG forKey:AVVideoCodecKey];
    [self.imageOutPut setOutputSettings:dicOutputSetting];
    
    //视频输出流
    //设置视频格式
    NSString *preset = self.sessionPreset ? : AVCaptureSessionPreset1280x720;
    if ([self.session canSetSessionPreset:preset]) {
        self.session.sessionPreset = preset;
    } else {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    
    self.movieFileOutPut = [[AVCaptureMovieFileOutput alloc] init];
    // 解决视频录制超过10s没有声音的bug
    self.movieFileOutPut.movieFragmentInterval = kCMTimeInvalid;
    
    //音频输入流
    AVCaptureDeviceInput *audioInput = nil;
    if (self.allowRecordVideo) {
        AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio].firstObject;
        audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:nil];
    }
    
    //添加视频/音频输入流
    if ([self.session canAddInput:self.deviceInput]) {
        [self.session addInput:self.deviceInput];
    }
    if (audioInput && [self.session canAddInput:audioInput]) {
        [self.session addInput:audioInput];
    }
    //添加视频/图片输出流
    if ([self.session canAddOutput:self.imageOutPut]) {
        [self.session addOutput:self.imageOutPut];
    }
    if ([self.session canAddOutput:self.movieFileOutPut]) {
        [self.session addOutput:self.movieFileOutPut];
    }
    
    //预览层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.view.layer setMasksToBounds:YES];
    
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    return YES;
}

#pragma mark - 手势
- (void)adjustFocusPoint:(UITapGestureRecognizer *)singleTap {
    if (!self.session.isRunning) return;
    
    CGPoint point = [singleTap locationInView:self.view];
    if (point.y > self.toolView.tl_top) {
        return;
    }
    [self setFocusCursorWithPoint:point];
}

#pragma mark - 监控设备方向
- (void)observeDeviceMotion {
    self.motionManager = [[CMMotionManager alloc] init];
    //提供设备运动数据到指定的时间间隔
    self.motionManager.deviceMotionUpdateInterval = 0.5;
    
    //确定是否使用任何可用的态度参考帧来决定设备的运动是否可用
    if (!self.motionManager.isDeviceMotionAvailable) {
        self.motionManager = nil;
        return;
    }
    //启动设备的运动更新，通过给定的队列向给定的处理程序提供数据。
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
    }];
}

- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion {
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    
    if (fabs(y) >= fabs(x)) {
        if (y >= 0){
            // UIDeviceOrientationPortraitUpsideDown;
            self.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
        } else {
            // UIDeviceOrientationPortrait;
            self.orientation = AVCaptureVideoOrientationPortrait;
        }
        return;
    }
    if (x >= 0) {
        //视频拍照转向，左右和屏幕转向相反
        // UIDeviceOrientationLandscapeRight;
        self.orientation = AVCaptureVideoOrientationLandscapeLeft;
    } else {
        // UIDeviceOrientationLandscapeLeft;
        self.orientation = AVCaptureVideoOrientationLandscapeRight;
    }
}

#pragma mark - 修改设备属性
//修改属性前使用此方法获取devide
- (void)changeDeviceProperty:(void (^)(AVCaptureDevice *device))block {
    AVCaptureDevice *device = [self.deviceInput device];
    NSError *error = nil;
    //改变设备属性前一定要先调用lockForConfiguration:，之后使用unlockForConfiguration解锁
    if (![device lockForConfiguration:&error]) {
        return;
    }
    if (block) {
        block(device);
    }
    [device unlockForConfiguration];
}

//设置聚焦光标位置
- (void)setFocusCursorWithPoint:(CGPoint)point {
    self.focusCursorImageView.center = point;
    self.focusCursorImageView.alpha = 1;
    self.focusCursorImageView.transform = CGAffineTransformMakeScale(1.25, 1.25);
    [UIView animateWithDuration:0.5 animations:^{
        self.focusCursorImageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursorImageView.alpha = 0;
    }];
    
    //将UI坐标转化为摄像头坐标
    CGPoint cameraPoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];
    [self setFocusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose point:cameraPoint];
}

//设置焦距
- (void)setVideoZoomFactor:(CGFloat)zoomFactor {
    /**
     iPhone8:minAvailableVideoZoomFactor = 1 maxAvailableVideoZoomFactor = 135
     */
    zoomFactor = MAX(zoomFactor, 1);
    
    [self changeDeviceProperty:^(AVCaptureDevice *device) {
        device.videoZoomFactor = zoomFactor;
    }];
}

//设置聚焦点和曝光点
- (void)setFocusWithMode:(AVCaptureFocusMode )focusMode exposureMode:(AVCaptureExposureMode)exposureMode point:(CGPoint)point {
    [self changeDeviceProperty:^(AVCaptureDevice *device) {
        //聚焦模式
        if ([device isFocusModeSupported:focusMode]) {
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        //聚焦点
        if ([device isFocusPointOfInterestSupported]) {
            [device setFocusPointOfInterest:point];
        }
        //曝光模式
        if ([device isExposureModeSupported:exposureMode]) {
            [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        //曝光点
        if ([device isExposurePointOfInterestSupported]) {
            [device setExposurePointOfInterest:point];
        }
    }];
}

//切换镜头
- (void)exchangeCameraPosition {
    //微信可以做到边录制边切换镜头，没想好是怎么做的
    NSUInteger cameraCount = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count;
    if (cameraCount <= 1) return;
    NSError *error;
    AVCaptureDeviceInput *newVideoInput;
    AVCaptureDevicePosition position = self.deviceInput.device.position;
    if (position == AVCaptureDevicePositionBack) {
        newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
    } else if (position == AVCaptureDevicePositionFront || position == AVCaptureDevicePositionUnspecified) {
        newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
    }
    if (error || newVideoInput == nil) {
        NSLog(@"切换摄像头失败");
        return;
    }
    [self.session beginConfiguration];
    [self.session removeInput:self.deviceInput];
    if ([self.session canAddInput:newVideoInput]) {
        [self.session addInput:newVideoInput];
        self.deviceInput = newVideoInput;
    }
    else {
        [self.session addInput:self.deviceInput];
    }
    [self.session commitConfiguration];
}

- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

#pragma mark - TLCameraToolViewDelegate
- (void)cameraToolViewDidTakePhoto:(TLCameraToolView *)toolView completion:(nonnull void (^)(BOOL))completion {
    AVCaptureConnection *videoConnection = [self.imageOutPut connectionWithMediaType:AVMediaTypeVideo];
    videoConnection.videoOrientation = self.orientation;
    if (!videoConnection) {
        completion(NO);
        return;
    }
    if (!_previewImageView) {
        _previewImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _previewImageView.backgroundColor = [UIColor blackColor];
        _previewImageView.hidden = YES;
        _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view insertSubview:_previewImageView belowSubview:self.toolView];
    }
    __weak typeof(self) weakSelf = self;
    [self.imageOutPut captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            completion(NO);
        }
        else {
            completion(YES);
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.switchButton.hidden = YES;
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            strongSelf.previewImageView.hidden = NO;
            strongSelf.previewImageView.image = [image tl_fixOrientation];
            [strongSelf.session stopRunning];
        }
    }];
}

- (void)cameraToolViewStartRecord:(TLCameraToolView *)toolView {
    AVCaptureConnection *connection = [self.movieFileOutPut connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = self.orientation;
    [connection setVideoScaleAndCropFactor:1.0];
    //视频防抖，没测过，默认AVCaptureVideoStabilizationModeOff
//    if (connection.isVideoStabilizationSupported) {
//        connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
//    }
    if (!self.movieFileOutPut.isRecording) {
        //mov mp4
        NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingFormat:@"TLCameraVideo.%@",self.videoType ? : @"mp4"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
        }
        NSURL *fileURL = [NSURL fileURLWithPath:outputFilePath];
        [self.movieFileOutPut startRecordingToOutputFileURL:fileURL recordingDelegate:self];
    }
}

- (void)cameraToolViewFinishRecord:(TLCameraToolView *)toolView {
    self.switchButton.hidden = YES;
    [self.movieFileOutPut stopRecording];
    [self setVideoZoomFactor:1];
}

- (void)cameraToolViewClickCancel:(TLCameraToolView *)toolView {
    self.switchButton.hidden = NO;
    [self.session startRunning];
    [self setFocusCursorWithPoint:self.view.center];
    
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
    [self.playerView reset];
    if (self.TLDoneBlock) {
        self.TLDoneBlock(self.previewImageView.image, self.videoUrl);
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)cameraToolViewClickDismiss:(TLCameraToolView *)toolView {
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraToolViewClickDismiss:(TLCameraToolView *)toolView setVideoZoomFactor:(CGFloat)zoomFactor {
    [self setVideoZoomFactor:zoomFactor];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    [self.toolView startAnimating];
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    //微信是最小分享1s的视频，可以在这里限制
    if (CMTimeGetSeconds(output.recordedDuration) < 1) {
        if (self.allowTakePhoto) {
            [self.toolView takePhoto];
            return;
        }
    }
    [self.session stopRunning];
    self.videoUrl = outputFileURL;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self playVideo];
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
