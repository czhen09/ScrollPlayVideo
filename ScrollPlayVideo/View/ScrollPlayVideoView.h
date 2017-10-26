//
//  ScrollPlayVideoView.h
//  ScrollPlayVideo
//
//  Created by 郑旭 on 2017/10/20.
//  Copyright © 2017年 郑旭. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScrollPlayVideoView : UIView
- (instancetype)init;
//设置初次跳转过来  起始播放时间
@property (nonatomic,assign) CGFloat startTimeValue;
@end
