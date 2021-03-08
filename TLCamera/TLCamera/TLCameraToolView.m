//
//  TLCameraToolView.m
//  TLCamera
//
//  Created by Will on 2021/3/3.
//

#import "TLCameraToolView.h"
#import "TLDefine.h"

static const CGFloat kTLRecordViewScale = 0.7;
static const CGFloat kTLRowLineHeight = 0.5f;
static const CGFloat kTLContentMargin = 30.0f;
static const CGFloat kTLContentPadding = 20.0f;

@interface TLCameraToolView ()<CAAnimationDelegate,UIGestureRecognizerDelegate>
{
    //防止动画和长按手势都调用FinishRecord
    BOOL _didStopRecord;
    BOOL _didLayoutSubviews;
    CGPoint _startReordPoint;
}

@property (nonatomic, strong) UILabel *tipLabel;

@property (nonatomic, strong) UIButton *dismissButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *doneButton;

@property (nonatomic, strong) UIView *pointView;
@property (nonatomic, strong) UIView *recordView;
@property (nonatomic, strong) CAShapeLayer *animationLayer;

@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation TLCameraToolView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
        self.clipsToBounds = NO;
        
        _tipLabel = [UILabel new];
        _tipLabel.font = [UIFont systemFontOfSize:14];
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.text = @"轻触拍照，按住摄像";
        _tipLabel.alpha = 0;
        
        _recordView = [UIView new];
        _recordView.layer.masksToBounds = YES;
        _recordView.backgroundColor = [kColorRGB(244, 244, 244) colorWithAlphaComponent:0.9];
        
        _pointView = [UIView new];
        _pointView.layer.masksToBounds = YES;
        _pointView.backgroundColor = [UIColor whiteColor];
        _pointView.userInteractionEnabled = NO;
        
        _dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_dismissButton setImage:[UIImage tl_imageWithNamed:@"tl_camera_dismiss"] forState:UIControlStateNormal];
        [_dismissButton setImage:[UIImage tl_imageWithNamed:@"tl_camera_dismiss"] forState:UIControlStateHighlighted];
        [_dismissButton addTarget:self action:@selector(dismissButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setImage:[UIImage tl_imageWithNamed:@"tl_camera_cancel"] forState:UIControlStateNormal];
        [_cancelButton setImage:[UIImage tl_imageWithNamed:@"tl_camera_cancel"] forState:UIControlStateHighlighted];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.hidden = YES;
        
        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _doneButton.frame = _recordView.frame;
        [_doneButton setImage:[UIImage tl_imageWithNamed:@"tl_camera_confirm"] forState:UIControlStateNormal];
        [_doneButton setImage:[UIImage tl_imageWithNamed:@"tl_camera_confirm"] forState:UIControlStateHighlighted];
        [_doneButton addTarget:self action:@selector(doneButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _doneButton.hidden = YES;
        
        [self tl_addSubviews:@[_tipLabel,_recordView,_pointView,_dismissButton,_cancelButton,_doneButton]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (_didLayoutSubviews) return;
    _didLayoutSubviews = YES;
    
    self.tipLabel.frame = CGRectMake(0, -30, self.tl_width, 20);
    //first time show
    [self setTipLabelAlpha:1 animated:YES];
    
    CGFloat recordViewWidth = self.tl_height * kTLRecordViewScale;
    self.recordView.frame = CGRectMake(0, 0, recordViewWidth, recordViewWidth);
    self.recordView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.recordView.layer.cornerRadius = recordViewWidth / 2;

    CGFloat pointWidth = self.tl_height * 0.5;
    self.pointView.frame = CGRectMake(0, 0, pointWidth, pointWidth);
    self.pointView.center = self.recordView.center;
    self.pointView.layer.cornerRadius = pointWidth / 2;
    
    self.dismissButton.frame = CGRectMake(60, (self.bounds.size.height - 25) / 2, 30, 30);

    self.cancelButton.frame = self.recordView.frame;
    
    self.doneButton.frame = self.recordView.frame;
}

- (void)dealloc {
    NSLog(@"%@ dealloc",self.class);
}

- (void)takePhoto {
    [self singleTapAction];
}

#pragma mar - Private Methods
- (void)setTipLabelAlpha:(CGFloat)alpha animated:(BOOL)animated {
    if (!self.allowTakePhoto || !self.allowRecordVideo) {
        return;
    }
    [self.tipLabel.layer removeAllAnimations];
    if (self.tipLabel.alpha == alpha) return;
    if (!animated) {
        self.tipLabel.alpha = alpha;
        return;
    }
    if (alpha == 1) {
        //alpha:0->1->0
        [UIView animateKeyframesWithDuration:3 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.1 animations:^{
                self.tipLabel.alpha = alpha;
            }];
            [UIView addKeyframeWithRelativeStartTime:0.9 relativeDuration:0.1 animations:^{
                self.tipLabel.alpha = 0;
            }];
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.25 animations:^{self.tipLabel.alpha = alpha;}];
    }
}

- (void)showCancelDoneButton {
    self.cancelButton.hidden = NO;
    self.doneButton.hidden = NO;
    
    CGRect cancelRect = self.cancelButton.frame;
    cancelRect.origin.x = 40;
    CGRect doneRect = self.doneButton.frame;
    doneRect.origin.x = self.tl_width - doneRect.size.width - 40;
    [UIView animateWithDuration:0.1 animations:^{
        self.cancelButton.frame = cancelRect;
        self.doneButton.frame = doneRect;
    }];
}

- (void)reset {
    if (_animationLayer.superlayer) {
        [self.animationLayer removeAllAnimations];
        [self.animationLayer removeFromSuperlayer];
    }
    self.dismissButton.hidden = NO;
    self.recordView.hidden = NO;
    self.pointView.hidden = NO;
    self.cancelButton.hidden = YES;
    self.doneButton.hidden = YES;
    
    self.cancelButton.frame = self.recordView.frame;
    self.doneButton.frame = self.recordView.frame;
}

#pragma mark - GestureRecognizer
- (void)singleTapAction {
    [self setTipLabelAlpha:0 animated:NO];
    
    self.recordView.hidden = YES;
    self.pointView.hidden = YES;
    self.dismissButton.hidden = YES;
    
    if (_delegate && [_delegate respondsToSelector:@selector(cameraToolViewDidTakePhoto:completion:)]) {
        //这里做回调是因为我的手机
        [_delegate cameraToolViewDidTakePhoto:self completion:^(BOOL success) {
            if (success) {
                [self showCancelDoneButton];
            }
            else {
                [self reset];
            }
        }];
    }
}

- (void)longPressAction:(UILongPressGestureRecognizer *)longPress {
    UIGestureRecognizerState state = longPress.state;
    if (state == UIGestureRecognizerStateBegan) {
        _didStopRecord = NO;
        _startReordPoint = [longPress locationInView:self];
        
        if (_delegate && [_delegate respondsToSelector:@selector(cameraToolViewStartRecord:)]) {
            [_delegate cameraToolViewStartRecord:self];
        }
    }
    else if (state == UIGestureRecognizerStateChanged) {
        if (_didStopRecord) return;
        CGFloat pointY = [longPress locationInView:self].y;
        CGFloat zoomFactor = pointY >= _startReordPoint.y ? 1 : (((_startReordPoint.y - pointY) / self.tl_top) * 10);
        if (_delegate && [_delegate respondsToSelector:@selector(cameraToolViewClickDismiss:setVideoZoomFactor:)]) {
            [_delegate cameraToolViewClickDismiss:self setVideoZoomFactor:zoomFactor];
        }
    }
    else if (state == UIGestureRecognizerStateEnded ||
             state == UIGestureRecognizerStateCancelled) {
        if (_didStopRecord) return;
        _didStopRecord = YES;
        [self stopAnimating];
        
        if (_delegate && [_delegate respondsToSelector:@selector(cameraToolViewFinishRecord:)]) {
            [_delegate cameraToolViewFinishRecord:self];
        }
    }
}

#pragma mark - Animation
- (void)startAnimating {
    self.dismissButton.hidden = YES;
    
    [UIView animateWithDuration:0.1 animations:^{
        self.recordView.layer.transform = CATransform3DScale(CATransform3DIdentity, 1 / kTLRecordViewScale, 1 / kTLRecordViewScale, 1);
        self.pointView.layer.transform = CATransform3DScale(CATransform3DIdentity, 0.7, 0.7, 1);
    } completion:^(BOOL finished) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.fromValue = @(0);
        animation.toValue = @(1);
        animation.duration = self.maxRecordDuration;
        animation.delegate = self;
        [self.animationLayer addAnimation:animation forKey:nil];

        [self.recordView.layer addSublayer:self.animationLayer];
    }];
}

- (void)stopAnimating {
    if (_animationLayer) {
        [self.animationLayer removeFromSuperlayer];
        [self.animationLayer removeAllAnimations];
    }
    
    self.recordView.hidden = YES;
    self.pointView.hidden = YES;
    self.dismissButton.hidden = YES;
    
    self.recordView.layer.transform = CATransform3DIdentity;
    self.pointView.layer.transform = CATransform3DIdentity;
    
    [self showCancelDoneButton];
}

//CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (_didStopRecord) return;
    _didStopRecord = YES;
    
    [self stopAnimating];
    
    if (_delegate && [_delegate respondsToSelector:@selector(cameraToolViewFinishRecord:)]) {
        [_delegate cameraToolViewFinishRecord:self];
    }
}

#pragma mark - Button Actions
- (void)dismissButtonAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(cameraToolViewClickDismiss:)]) {
        [_delegate cameraToolViewClickDismiss:self];
    }
}

- (void)cancelButtonAction:(UIButton *)sender {
    [self setTipLabelAlpha:1 animated:YES];
    [self reset];
    
    if (_delegate && [_delegate respondsToSelector:@selector(cameraToolViewClickCancel:)]) {
        [_delegate cameraToolViewClickCancel:self];
    }
}

- (void)doneButtonAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(cameraToolViewClickDone:)]) {
        [_delegate cameraToolViewClickDone:self];
    }
}

#pragma mark - Setters
- (void)setAllowTakePhoto:(BOOL)allowTakePhoto {
    _allowTakePhoto = allowTakePhoto;
    if (allowTakePhoto) {
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction)];
        [self.recordView addGestureRecognizer:singleTap];
    }
}

- (void)setAllowRecordVideo:(BOOL)allowRecordVideo {
    _allowRecordVideo = allowRecordVideo;
    if (allowRecordVideo) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        longPress.minimumPressDuration = 0.3;
        longPress.delegate = self;
        [self.recordView addGestureRecognizer:longPress];
    }
}

#pragma mark - Getters
- (CAShapeLayer *)animationLayer {
    if (_animationLayer == nil) {
        _animationLayer = [CAShapeLayer layer];
        
        CGFloat width = CGRectGetHeight(self.recordView.frame) * kTLRecordViewScale;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, width, width) cornerRadius:width/2];
        _animationLayer.strokeColor = self.progressColor.CGColor;
        _animationLayer.fillColor = [UIColor clearColor].CGColor;
        _animationLayer.path = path.CGPath;
        _animationLayer.lineWidth = 8;
    }
    return _animationLayer;
}

@end


@implementation TLCameraAlertView

+ (id)showWithTitle:(NSString *)title handler:(void (^)(void))actionSheetBlock {
    TLCameraAlertView *alertView = [[TLCameraAlertView alloc] initWithFrame:[UIScreen mainScreen].bounds title:title handler:actionSheetBlock];
    [alertView showInView:nil];
    return alertView;
}

- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title handler:(void (^)(void))actionSheetBlock {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.alpha = 0;
        
        self.actionSheetBlock = actionSheetBlock;
        
        CGFloat contentWidth = frame.size.width - kTLContentMargin * 2;
        CGFloat textMaxWidth = contentWidth - kTLContentPadding * 2;
        CGFloat contentHeight = 0;
        UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        [self addSubview:backgroundView];
        
        UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
        contentView.backgroundColor = UIColor.whiteColor;
        contentView.layer.cornerRadius = 4.0;
        contentView.clipsToBounds = YES;
        [self addSubview:contentView];
        
        UILabel *titleLabel = [UILabel new];
        titleLabel.numberOfLines = 0;
        titleLabel.font = [UIFont systemFontOfSize:16];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.text = title;
        
        CGSize titleSize = [titleLabel sizeThatFits:CGSizeMake(textMaxWidth, CGFLOAT_MAX)];
        titleSize.height = titleSize.height <= 25 ? 25 : titleSize.height;
        titleLabel.frame = CGRectMake(kTLContentPadding, 25, textMaxWidth, titleSize.height);
        
        contentHeight = CGRectGetMaxY(titleLabel.frame);
        [contentView addSubview:titleLabel];
        
        UIView *horLine = [[UIView alloc] initWithFrame:CGRectMake(0, contentHeight + 25, contentWidth, kTLRowLineHeight)];
        horLine.backgroundColor = kColorRGB(221, 221, 221);
        [contentView addSubview:horLine];
        contentHeight = CGRectGetMaxY(horLine.frame);
        
        UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [doneButton setTitle:@"确认" forState:0];
        [doneButton setTitleColor:kColorRGB(255, 153, 116) forState:0];
        [doneButton setTitleColor:UIColor.lightGrayColor forState:UIControlStateHighlighted];
        doneButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [doneButton addTarget:self action:@selector(as_doneButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        doneButton.frame = CGRectMake(0, CGRectGetMaxY(horLine.frame), contentWidth, 50);
        [contentView addSubview:doneButton];
        contentHeight = CGRectGetMaxY(doneButton.frame);
        
        contentView.frame = CGRectMake((frame.size.width - contentWidth) / 2.0, (frame.size.height - contentHeight) / 2.0, contentWidth, contentHeight);
    }
    return self;
}

- (void)showInView:(UIView * __nullable)view {
    if (view == nil || ![view isKindOfClass:[UIView class]]) {
        view = [UIApplication.sharedApplication.delegate respondsToSelector:@selector(window)] ? [UIApplication.sharedApplication.delegate window] : [UIApplication.sharedApplication keyWindow];
    }
    [view.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:self.class]) {
            [obj removeFromSuperview];
            *stop = YES;
        }
    }];
    
    [view addSubview:self];
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)as_doneButtonAction:(UIButton *)sender {
    if (self.actionSheetBlock) {
        self.actionSheetBlock();
    }
    [self dismiss];
}

@end
