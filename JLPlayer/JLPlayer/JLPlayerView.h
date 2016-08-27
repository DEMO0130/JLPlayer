//
//  JLPlayerView.h
//  JLPlayer
//
//  Created by DEMO on 16/8/27.
//  Copyright © 2016年 DEMO. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  屏幕横竖屏枚举
 */
typedef NS_ENUM(NSInteger, JLPlayerOrientation) {
    /**
     *  竖屏
     */
    JLPlayerOrientationPortrait = 1,
    /**
     *  横屏
     */
    JLPlayerOrientationLandscape = 2
};

@interface JLPlayerView : UIView

@property (nonatomic, assign) JLPlayerOrientation deviceOrientation;

/**
 *  指定初始化方法
 *
 *  @param resourceUrlStr 播放资源的路径
 *  @param frame
 *
 *  @return 
 */
- (instancetype)initWithResourceUrlStr:(NSString *)resourceUrlStr Frame:(CGRect)frame;
@end
