//
//  SBControlView.m
//  SBPlayer
//
//  Created by sycf_ios on 2017/4/10.
//  Copyright © 2017年 shibiao. All rights reserved.
//

#import "SBControlView.h"
@interface SBControlView ()
//当前时间
@property (nonatomic,strong) UILabel *timeLabel;
//总时间
@property (nonatomic,strong) UILabel *totalTimeLabel;
//进度条
@property (nonatomic,strong) UISlider *slider;
//缓存进度条
@property (nonatomic,strong) UISlider *bufferSlier;
@end
static NSInteger padding = 8;
@implementation SBControlView
//懒加载
-(UILabel *)timeLabel{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc]init];
        _timeLabel.textAlignment = NSTextAlignmentRight;
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = [UIColor whiteColor];
    }
    return _timeLabel;
}
-(UILabel *)totalTimeLabel{
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc]init];
        _totalTimeLabel.textAlignment = NSTextAlignmentLeft;
        _totalTimeLabel.font = [UIFont systemFontOfSize:12];
        _totalTimeLabel.textColor = [UIColor whiteColor];
    }
    return _totalTimeLabel;
}
-(UISlider *)slider{
    if (!_slider) {
        _slider = [[UISlider alloc]init];
        [_slider setThumbImage:[UIImage imageNamed:@"knob"] forState:UIControlStateNormal];
        _slider.continuous = YES;
        self.tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
        [_slider addTarget:self action:@selector(handleSliderPosition:) forControlEvents:UIControlEventValueChanged];
        [_slider addGestureRecognizer:self.tapGesture];
        _slider.maximumTrackTintColor = [UIColor clearColor];
        _slider.minimumTrackTintColor = [UIColor whiteColor];
    }
    return _slider;
}
-(UIButton *)largeButton{
    if (!_largeButton) {
        _largeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _largeButton.contentMode = UIViewContentModeScaleToFill;
        [_largeButton setImage:[UIImage imageNamed:@"full_screen"] forState:UIControlStateNormal];
        [_largeButton addTarget:self action:@selector(hanleLargeBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _largeButton;
}
-(UISlider *)bufferSlier{
    if (!_bufferSlier) {
        _bufferSlier = [[UISlider alloc]init];
        [_bufferSlier setThumbImage:[UIImage new] forState:UIControlStateNormal];
        _bufferSlier.continuous = YES;
        _bufferSlier.minimumTrackTintColor = [UIColor redColor];
        _bufferSlier.minimumValue = 0.f;
        _bufferSlier.maximumValue = 1.f;
        _bufferSlier.userInteractionEnabled = NO;
    }
    return _bufferSlier;
}
- (void)drawRect:(CGRect)rect {
    [self setupUI];

}
-(void)setupUI{
    [self addSubview:self.timeLabel];
    [self addSubview:self.bufferSlier];
    [self addSubview:self.slider];
    [self addSubview:self.totalTimeLabel];
    [self addSubview:self.largeButton];
    //添加约束
    [self addConstraintsForSubviews];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}
-(void)deviceOrientationDidChange{
    //添加约束
    [self addConstraintsForSubviews];
}
-(void)addConstraintsForSubviews{
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self);
        make.bottom.mas_equalTo(self).offset(-padding);
        make.right.mas_equalTo(self.slider).offset(-padding).priorityLow();
        make.width.mas_equalTo(@50);
        make.centerY.mas_equalTo(@[self.timeLabel,self.slider,self.totalTimeLabel,self.largeButton]);
    }];
    [self.slider mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.timeLabel.mas_right).offset(padding);
        make.right.mas_equalTo(self.totalTimeLabel.mas_left).offset(-padding);
        if (kScreenWidth<kScreenHeight) {
            //后面的几个常数分别是各个控件的间隔和控件的宽度  添加自定义控件需在此修改参数
            make.width.mas_equalTo(kScreenWidth - padding - 50 - 50 - 30 - padding - padding);
        }
    }];
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.slider.mas_right).offset(padding);
        make.right.mas_equalTo(self.largeButton.mas_left);
        make.bottom.mas_equalTo(self).offset(-padding);
        make.width.mas_equalTo(@50).priorityHigh();
    }];
    [self.largeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.right.mas_equalTo(self).offset(-padding);
        make.left.mas_equalTo(self.totalTimeLabel.mas_right);
        make.width.height.mas_equalTo(@30);
    }];
    [self.bufferSlier mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.slider);
    }];
    [self layoutIfNeeded];
}
-(void)hanleLargeBtn:(UIButton *)button{
    if ([self.delegate respondsToSelector:@selector(controlView:withLargeButton:)]) {
        [self.delegate controlView:self withLargeButton:button];
    }
}
-(void)handleSliderPosition:(UISlider *)slider{
    if ([self.delegate respondsToSelector:@selector(controlView:draggedPositionWithSlider:)]) {
        [self.delegate controlView:self draggedPositionWithSlider:self.slider];
    }
}
-(void)handleTap:(UITapGestureRecognizer *)gesture{
    CGPoint point = [gesture locationInView:self.slider];
    CGFloat pointX = point.x;
    CGFloat sliderWidth = self.slider.frame.size.width;
    CGFloat currentValue = pointX/sliderWidth * self.slider.maximumValue;
    if ([self.delegate respondsToSelector:@selector(controlView:pointSliderLocationWithCurrentValue:)]) {
        [self.delegate controlView:self pointSliderLocationWithCurrentValue:currentValue];
    }
}

//setter 和 getter方法
-(void)setValue:(CGFloat)value{
    self.slider.value = value;
}
-(CGFloat)value{
    return self.slider.value;
}
-(void)setMinValue:(CGFloat)minValue{
    self.slider.minimumValue = minValue;
}
-(CGFloat)minValue{
    return self.slider.minimumValue;
}
-(void)setMaxValue:(CGFloat)maxValue{
    self.slider.maximumValue = maxValue;
}
-(CGFloat)maxValue{
    return self.slider.maximumValue;
}
-(void)setCurrentTime:(NSString *)currentTime{
    self.timeLabel.text = currentTime;
}
-(NSString *)currentTime{
    return self.timeLabel.text;
}
-(void)setTotalTime:(NSString *)totalTime{
    self.totalTimeLabel.text = totalTime;
}
-(NSString *)totalTime{
    return self.totalTimeLabel.text;
}
-(CGFloat)bufferValue{
    return self.bufferSlier.value;
}
-(void)setBufferValue:(CGFloat)bufferValue{
    self.bufferSlier.value = bufferValue;
}
@end
