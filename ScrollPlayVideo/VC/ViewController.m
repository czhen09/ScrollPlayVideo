//
//  ViewController.m
//  ScrollPlayVideo
//
//  Created by 郑旭 on 2017/10/20.
//  Copyright © 2017年 郑旭. All rights reserved.
//

#import "ViewController.h"
#import "ScrollPlayVideoView.h"
#import <Masonry.h>
@interface ViewController ()
@property (nonatomic,strong) ScrollPlayVideoView  *scrollPlayView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addSubViews];
}
- (void)addSubViews
{
    [self.view addSubview:self.scrollPlayView];
    [self.scrollPlayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.left.bottom.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).offset(64);
    }];
}
- (ScrollPlayVideoView *)scrollPlayView
{
    if (!_scrollPlayView) {
        _scrollPlayView = [[ScrollPlayVideoView alloc] init];
    }
    return _scrollPlayView;
}
@end
