//
//  TLPlayer.h
//  TLCamera
//
//  Created by Will on 2021/1/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLPlayer : UIView

@property (nonatomic, strong) NSURL *videoUrl;

@property (nonatomic, assign, readonly) BOOL isPlaying;

///开始播放
- (void)play;

///暂停
- (void)pause;

///重置
- (void)reset;

@end

NS_ASSUME_NONNULL_END
