//
//  TLPlayer.m
//  TLCamera
//
//  Created by Will on 2021/1/6.
//

#import "TLPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface TLPlayer ()

@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation TLPlayer

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        self.playerLayer = [[AVPlayerLayer alloc] init];
        self.playerLayer.frame = self.bounds;
        [self.layer addSublayer:self.playerLayer];
    }
    return self;
}

- (void)dealloc {
    [_player pause];
    _player = nil;
}

- (void)setVideoUrl:(NSURL *)videoUrl {
    _player = [AVPlayer playerWithURL:videoUrl];
    if (@available(iOS 10.0, *)) {
        _player.automaticallyWaitsToMinimizeStalling = NO;
    }
    
    __weak typeof(self) weakSelf = self;
    [NSNotificationCenter.defaultCenter addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.player seekToTime:kCMTimeZero];
        [strongSelf.player play];
    }];
    
    self.playerLayer.player = _player;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
}

- (void)play {
    [_player play];
}

- (void)pause {
    [_player pause];
}

- (void)reset {
    [_player pause];
    _player = nil;
}

- (BOOL)isPlaying {
    return _player && _player.rate > 0;
}

@end
