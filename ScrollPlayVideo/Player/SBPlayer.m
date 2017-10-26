//
//  SBView.m
//  SBPlayer
//
//  Created by sycf_ios on 2017/4/10.
//  Copyright © 2017年 shibiao. All rights reserved.
//

#import "SBPlayer.h"
@interface SBPlayer ()

@property (nonatomic,strong,readonly) AVPlayerLayer *playerLayer;
//当前播放url
@property (nonatomic,strong) NSURL *url;
//底部控制视图
@property (nonatomic,strong) SBControlView *controlView;

//原始约束
@property (nonatomic,strong) NSArray *oldConstriants;
//添加标题
@property (nonatomic,strong) UILabel *titleLabel;
//加载动画
@property (nonatomic,strong) UIActivityIndicatorView *activityIndeView;
@property (nonatomic,assign) BOOL isShouldToHiddenSubviews;
@property (nonatomic,strong) UIButton  *playOrPauseButton;
@property (nonatomic,assign) BOOL isFirstPrepareToPlay;
@end
static NSInteger count = 0;

@implementation SBPlayer
+(Class)layerClass{
    return [AVPlayerLayer class];
}
//MARK: Get方法和Set方法
-(AVPlayer *)player{
    return self.playerLayer.player;
}
-(void)setPlayer:(AVPlayer *)player{
    self.playerLayer.player = player;
}
-(AVPlayerLayer *)playerLayer{
    return (AVPlayerLayer *)self.layer;
}
-(CGFloat)rate{
    return self.player.rate;
}
-(void)setRate:(CGFloat)rate{
    self.player.rate = rate;
}
-(void)setMode:(SBLayerVideoGravity)mode{
    switch (mode) {
        case SBLayerVideoGravityResizeAspect:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case SBLayerVideoGravityResizeAspectFill:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        case SBLayerVideoGravityResize:
            self.playerLayer.videoGravity = AVLayerVideoGravityResize;
            break;
    }
}
-(void)setTitle:(NSString *)title{
    self.titleLabel.text = title;
}
-(NSString *)title{
    return self.titleLabel.text;
}
//MARK:实例化
-(instancetype)initWithUrl:(NSURL *)url{
    self = [super init];
    if (self) {
        _url = url;
        [self setupPlayerUI];
        [self assetWithURL:url];
    }
    return self;
}
-(void)assetWithURL:(NSURL *)url{
    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    self.anAsset = [[AVURLAsset alloc]initWithURL:url options:options];
    NSArray *keys = @[@"duration"];

    [self.anAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSError *error = nil;
        AVKeyValueStatus tracksStatus = [self.anAsset statusOfValueForKey:@"duration" error:&error];
        switch (tracksStatus) {
            case AVKeyValueStatusLoaded:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!CMTIME_IS_INDEFINITE(self.anAsset.duration)) {
                        
                        if (self.anAsset.duration.timescale>0) {
                            CGFloat second = self.anAsset.duration.value / self.anAsset.duration.timescale;
                            self.controlView.totalTime = [self convertTime:second];
                            self.controlView.minValue = 0;
                            self.controlView.maxValue = second;
                        }
                    }
                });
            }
                break;
            case AVKeyValueStatusFailed:
            {
                //NSLog(@"AVKeyValueStatusFailed失败,请检查网络,或查看plist中是否添加App Transport Security Settings");
            }
                break;
            case AVKeyValueStatusCancelled:
            {
                NSLog(@"AVKeyValueStatusCancelled取消");
            }
                break;
            case AVKeyValueStatusUnknown:
            {
                NSLog(@"AVKeyValueStatusUnknown未知");
            }
                break;
            case AVKeyValueStatusLoading:
            {
                NSLog(@"AVKeyValueStatusLoading正在加载");
            }
                break;
        }
    }];
    [self setupPlayerWithAsset:self.anAsset];

}
-(instancetype)initWithAsset:(AVURLAsset *)asset{
    self = [super init];
    if (self) {
        [self setupPlayerUI];
        [self setupPlayerWithAsset:asset];
    }
    return self;
}
-(void)setupPlayerWithAsset:(AVURLAsset *)asset{
    self.item = [[AVPlayerItem alloc]initWithAsset:asset];
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.item];
    [self.playerLayer displayIfNeeded];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self addPeriodicTimeObserver];
    //添加KVO
    [self addKVO];
    //添加消息中心
    [self addNotificationCenter];
}
//FIXME: Tracking time,跟踪时间的改变
-(void)addPeriodicTimeObserver{
    __weak typeof(self) weakSelf = self;
    playbackTimerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.f, 1.f) queue:NULL usingBlock:^(CMTime time) {
        weakSelf.controlView.value = weakSelf.item.currentTime.value/weakSelf.item.currentTime.timescale;
        if (!CMTIME_IS_INDEFINITE(self.anAsset.duration)) {
            weakSelf.controlView.currentTime = [weakSelf convertTime:weakSelf.controlView.value];
        }
        NSLog(@"%f",weakSelf.controlView.value);
        if (count>=5) {
            [weakSelf setSubViewsIsHide:YES];
            if ([weakSelf.delegate respondsToSelector:@selector(playerTapActionWithIsShouldToHideSubviews:)]) {
                [weakSelf.delegate playerTapActionWithIsShouldToHideSubviews:YES];
            }
        }else{
            [weakSelf setSubViewsIsHide:NO];
            if ([weakSelf.delegate respondsToSelector:@selector(playerTapActionWithIsShouldToHideSubviews:)]) {
                [weakSelf.delegate playerTapActionWithIsShouldToHideSubviews:NO];
            }
        }
        count += 1;
    }];
}
//TODO: KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus itemStatus = [[change objectForKey:NSKeyValueChangeNewKey]integerValue];
        
        switch (itemStatus) {
            case AVPlayerItemStatusUnknown:
            {
                _status = SBPlayerStatusUnknown;
                NSLog(@"AVPlayerItemStatusUnknown");
            }
                break;
            case AVPlayerItemStatusReadyToPlay:
            {
                _status = SBPlayerStatusReadyToPlay;
                NSLog(@"AVPlayerItemStatusReadyToPlay");
            }
                break;
            case AVPlayerItemStatusFailed:
            {
                _status = SBPlayerStatusFailed;
                NSLog(@"AVPlayerItemStatusFailed");
            }
                break;
            default:
                break;
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {  //监听播放器的下载进度
        NSArray *loadedTimeRanges = [self.item loadedTimeRanges];
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
        CMTime duration = self.item.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        //缓存值
        self.controlView.bufferValue=timeInterval / totalDuration;
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { //监听播放器在缓冲数据的状态
//        self.pauseOrPlayView.hidden = YES;
        _status = SBPlayerStatusBuffering;
        if (!self.activityIndeView.isAnimating) {
            [self setSubViewsIsHide:YES];
            self.activityIndeView.hidden = NO;
            [self.activityIndeView startAnimating];
        }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        
        if (self.isFirstPrepareToPlay) {
            NSLog(@"缓冲达到可播放");
            [self.activityIndeView stopAnimating];
            self.activityIndeView.hidden = YES;
            [self setSubViewsIsHide:YES];
            //改动
            //self.pauseOrPlayView.hidden = YES;
            [self play];
            self.isFirstPrepareToPlay = NO;
        }
    } else if ([keyPath isEqualToString:@"rate"]){//当rate==0时为暂停,rate==1时为播放,当rate等于负数时为回放
        if ([[change objectForKey:NSKeyValueChangeNewKey]integerValue]==0) {
            _isPlaying=false;
            _status = SBPlayerStatusPlaying;
        }else{
            
            _isPlaying=true;
            _status = SBPlayerStatusStopped;
        }
    }
}
//添加KVO
-(void)addKVO{
    
    if (self.item||self.item!=nil) {
        //监听状态属性
        [self.item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        //监听网络加载情况属性
        [self.item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        //监听播放的区域缓存是否为空
        [self.item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        //缓存可以播放的时候调用
        [self.item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
    if (self.player||self.player!=nil) {
        //监听暂停或者播放中
        [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    }
}
//MARK:添加消息中心
-(void)addNotificationCenter{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(SBPlayerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}
//MARK: NotificationCenter
-(void)SBPlayerItemDidPlayToEndTimeNotification:(NSNotification *)notification{
    [self.item seekToTime:kCMTimeZero];
    [self setSubViewsIsHide:NO];
    count = 0;
    [self pause];
    [self.playOrPauseButton setSelected:NO];
}
-(void)deviceOrientationDidChange:(NSNotification *)notification{
    UIInterfaceOrientation _interfaceOrientation=[[UIApplication sharedApplication]statusBarOrientation];
    switch (_interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            _isFullScreen = YES;
            if (!self.oldConstriants) {
                self.oldConstriants = [self getCurrentVC].view.constraints;
            }
            [self.controlView updateConstraintsIfNeeded];
            //删除UIView animate可以去除横竖屏切换过渡动画
            [UIView animateWithDuration:kTransitionTime delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0. options:UIViewAnimationOptionTransitionCurlUp animations:^{
                [[UIApplication sharedApplication].keyWindow addSubview:self];
                [self mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.edges.mas_equalTo([UIApplication sharedApplication].keyWindow);
                }];
                [self layoutIfNeeded];
            } completion:nil];
        }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationPortrait:
        {
            _isFullScreen = NO;
            [self.playerSuperView addSubview:self];
            //删除UIView animate可以去除横竖屏切换过渡动画
            [UIView animateKeyframesWithDuration:kTransitionTime delay:0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
                [self mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.top.left.right.bottom.mas_equalTo(self.playerSuperView);
                }];
                [self layoutIfNeeded];
            } completion:nil];
        }
            break;
        case UIInterfaceOrientationUnknown:
            NSLog(@"UIInterfaceOrientationUnknown");
            break;
    }
    [[self getCurrentVC].view layoutIfNeeded];

}
-(void)willResignActive:(NSNotification *)notification{
    if (_isPlaying) {
        [self setSubViewsIsHide:NO];
        count = 0;
        [self pause];
        [self.playOrPauseButton setSelected:NO];
    }
}

//获取当前屏幕显示的viewcontroller
- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    return result;
}
//- (void)drawRect:(CGRect)rect {
//    [self setupPlayerUI];
//}
//MARK: 设置界面 在此方法下面可以添加自定义视图，和删除视图
-(void)setupPlayerUI{
    [self setSubViewsIsHide:YES];
    self.activityIndeView.hidden = NO;
    [self.activityIndeView startAnimating];
    //添加标题
    [self addTitle];
    //添加点击事件
    [self addGestureEvent];
    //添加控制视图
    [self addControlView];
    //添加加载视图
    [self addLoadingView];
    //初始化时间
    [self initTimeLabels];
    //播放暂停
    [self addPlayOrPauseButton];
    self.playOrPauseButton.hidden = YES;
    self.isFirstPrepareToPlay = YES;
}
- (void )addPlayOrPauseButton
{
    [self addSubview:self.playOrPauseButton];
    [self.playOrPauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.width.height.mas_equalTo(70);
    }];
}
//初始化时间
-(void)initTimeLabels{
    self.controlView.currentTime = @"00:00";
    self.controlView.totalTime = @"00:00";
}
//添加加载视图
-(void)addLoadingView{
    [self addSubview:self.activityIndeView];
    [self.activityIndeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(@80);
        make.center.mas_equalTo(self);
    }];
}
//添加标题
-(void)addTitle{
    [self addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self);
        make.top.mas_equalTo(self).offset(12);
        make.width.mas_equalTo(self.mas_width);
    }];
}
//添加点击事件
-(void)addGestureEvent{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapAction:)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
}
-(void)handleTapAction:(UITapGestureRecognizer *)gesture{
    if (self.isHidenAllSubviews) {
        if ([self.delegate respondsToSelector:@selector(playerTapActionWithCurrentTimeValue:)]) {
            [self.delegate playerTapActionWithCurrentTimeValue:self.controlView.value];
        }
    }else{
        self.isShouldToHiddenSubviews = !self.isShouldToHiddenSubviews;
        if (self.isShouldToHiddenSubviews) {
            [self setSubViewsIsHide:NO];
            count = 0;
            if ([self.delegate respondsToSelector:@selector(playerTapActionWithIsShouldToHideSubviews:)]) {
                [self.delegate playerTapActionWithIsShouldToHideSubviews:NO];
            }
        }else{
            
            [self setSubViewsIsHide:YES];
            count = 5;
            if ([self.delegate respondsToSelector:@selector(playerTapActionWithIsShouldToHideSubviews:)]) {
                [self.delegate playerTapActionWithIsShouldToHideSubviews:YES];
            }
        }
    }
   
}
- (void)playOrPauseButtonClick:(UIButton *)button
{
    if (self.activityIndeView.isAnimating) {
        [self.activityIndeView stopAnimating];
        self.activityIndeView.hidden = YES;
    }
    if (!_isPlaying) {
        [self play];
    }else{
        [self pause];
    }
}
//添加控制视图
-(void)addControlView{

    [self addSubview:self.controlView];
    [self.controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self);
        make.height.mas_equalTo(@44);
    }];
    [self layoutIfNeeded];
}
//懒加载ActivityIndicateView
-(UIActivityIndicatorView *)activityIndeView{
    if (!_activityIndeView) {
        _activityIndeView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndeView.hidesWhenStopped = YES;
    }
    return _activityIndeView;
}
//懒加载标题
-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont systemFontOfSize:15];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.numberOfLines = 2;
    }
    return _titleLabel;
}

//懒加载控制视图
-(SBControlView *)controlView{
    if (!_controlView) {
        _controlView = [[SBControlView alloc]init];
        _controlView.delegate = self;
        _controlView.backgroundColor = [UIColor clearColor];
//        [_controlView.tapGesture requireGestureRecognizerToFail:self.pauseOrPlayView.imageBtn.gestureRecognizers.firstObject];
    }
    return _controlView;
}
//设置子视图是否隐藏
-(void)setSubViewsIsHide:(BOOL)isHide{
    self.controlView.hidden = isHide;
    self.playOrPauseButton.hidden = isHide;
    self.titleLabel.hidden = isHide;
}

//MARK: SBControlViewDelegate
-(void)controlView:(SBControlView *)controlView pointSliderLocationWithCurrentValue:(CGFloat)value{
    
    count = 0;
    CMTime pointTime = CMTimeMake(value * self.item.currentTime.timescale, self.item.currentTime.timescale);
    [self.item seekToTime:pointTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
-(void)controlView:(SBControlView *)controlView draggedPositionWithSlider:(UISlider *)slider{
    count = 0;
    CMTime pointTime = CMTimeMake(controlView.value * self.item.currentTime.timescale, self.item.currentTime.timescale);
    [self.item seekToTime:pointTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
- (void)setPlayerTimeValueTo:(CGFloat)value
{
    CMTime pointTime = CMTimeMake(value*self.item.currentTime.timescale, self.item.currentTime.timescale);
    [self.item seekToTime:pointTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
-(void)controlView:(SBControlView *)controlView withLargeButton:(UIButton *)button{
    count = 0;
    if (kScreenWidth<kScreenHeight) {
        [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
    }else{
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
    }
}
//MARK: UIGestureRecognizer
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isKindOfClass:[SBControlView class]]) {
        return NO;
    }
    return YES;
}
//将数值转换成时间
- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}
//旋转方向
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector             = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val                  = orientation;
        
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
    if (orientation == UIInterfaceOrientationLandscapeRight||orientation == UIInterfaceOrientationLandscapeLeft) {
        // 设置横屏
    } else if (orientation == UIInterfaceOrientationPortrait) {
        // 设置竖屏
    }else if (orientation == UIInterfaceOrientationPortraitUpsideDown){
        //
    }
}

-(void)play{
    if (self.player) {
        [self.player play];
        [self.playOrPauseButton setSelected:YES];
    }
}
-(void)pause{
    if (self.player) {
        [self.player pause];
        [self.playOrPauseButton setSelected:NO];
    }
}
-(void)stop{
    
    if (self.item||self.item!=nil) {
        [self.item removeObserver:self forKeyPath:@"status"];
        [self.item removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [self.item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    if (self.player||self.player!=nil) {
        [self.player removeTimeObserver:playbackTimerObserver];
        [self.player removeObserver:self forKeyPath:@"rate"];
    }
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    if (self.player) {
        [self pause];
        self.anAsset = nil;
        self.item = nil;
        self.controlView.value = 0;
        self.controlView.currentTime = @"00:00";
        self.controlView.totalTime = @"00:00";
        self.player = nil;
        [self.activityIndeView removeFromSuperview];
        self.activityIndeView = nil;
        [self removeFromSuperview];
    }
}
- (UIButton *)playOrPauseButton
{
    if (!_playOrPauseButton) {
        _playOrPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playOrPauseButton setImage:[UIImage imageNamed:@"播放按钮"] forState:UIControlStateNormal];
        [_playOrPauseButton setShowsTouchWhenHighlighted:YES];
        [_playOrPauseButton setImage:[UIImage imageNamed:@"播放按钮 暂停"] forState:UIControlStateSelected];
        [_playOrPauseButton addTarget:self action:@selector(playOrPauseButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playOrPauseButton;
}
- (void)setIsHidenAllSubviews:(BOOL)isHidenAllSubviews
{
    _isHidenAllSubviews = isHidenAllSubviews;
    if (isHidenAllSubviews) {
        [self.controlView removeFromSuperview];
        [self.playOrPauseButton removeFromSuperview];
        [self.titleLabel removeFromSuperview];
        self.player.volume = 0;
    }
}
@end
