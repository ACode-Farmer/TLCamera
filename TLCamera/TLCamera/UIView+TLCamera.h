//
//  UIView+TLCamera.h
//  TLCamera
//
//  Created by Will on 2021/1/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (TLCamera)

@property (nonatomic) CGFloat tl_left;        ///< Shortcut for frame.origin.x.
@property (nonatomic) CGFloat tl_top;         ///< Shortcut for frame.origin.y
@property (nonatomic) CGFloat tl_right;       ///< Shortcut for frame.origin.x + frame.size.width
@property (nonatomic) CGFloat tl_bottom;      ///< Shortcut for frame.origin.y + frame.size.height
@property (nonatomic) CGFloat tl_width;       ///< Shortcut for frame.size.width.
@property (nonatomic) CGFloat tl_height;      ///< Shortcut for frame.size.height.
@property (nonatomic) CGFloat tl_centerX;     ///< Shortcut for center.x
@property (nonatomic) CGFloat tl_centerY;     ///< Shortcut for center.y
@property (nonatomic) CGPoint tl_origin;      ///< Shortcut for frame.origin.
@property (nonatomic) CGSize  tl_size;        ///< Shortcut for frame.size.

- (void)tl_removeAllSubViews;

- (void)tl_addSubviews:(NSArray *)subviews;

@end

NS_ASSUME_NONNULL_END
