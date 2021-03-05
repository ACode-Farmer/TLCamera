//
//  UIView+TLCamera.m
//  TLCamera
//
//  Created by Will on 2021/1/6.
//

#import "UIView+TLCamera.h"

@implementation UIView (TLCamera)

- (CGFloat)tl_left {
    return self.frame.origin.x;
}

- (void)setTl_left:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)tl_top {
    return self.frame.origin.y;
}

- (void)setTl_top:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)tl_right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setTl_right:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}

- (CGFloat)tl_bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setTl_bottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)tl_width {
    return self.frame.size.width;
}

- (void)setTl_width:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)tl_height {
    return self.frame.size.height;
}

- (void)setTl_height:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)tl_centerX {
    return self.center.x;
}

- (void)setTl_centerX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)tl_centerY {
    return self.center.y;
}

- (void)setTl_centerY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}

- (CGPoint)tl_origin {
    return self.frame.origin;
}

- (void)setTl_origin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)tl_size {
    return self.frame.size;
}

- (void)setTl_size:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (void)tl_removeAllSubViews {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)tl_addSubviews:(NSArray *)subviews {
    [subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        if ([view isKindOfClass:[UIView class]]) {
            [self addSubview:view];
        }
    }];
}

@end
