//
//  JLPlayerView.m
//  JLPlayer
//
//  Created by DEMO on 16/8/27.
//  Copyright © 2016年 DEMO. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "JLPlayerView.h"

static NSString * kDefaultResourceUrlStr = @"http://go2study8.pinnc.com/videos/1234567.mp4";
static NSString * kDefaultSliderBlackImageName = @"sliderBlack.png";
static NSString * kDefaultSliderRedImageName = @"sliderRed.png";
static NSString * kDefaultSliderPotImageName = @"sliderPot.png";
static NSString * kScaleBtnMaxImageName = @"videoMax.png";
static NSString * kScaleBtnMinImageName = @"videoMin.png";


static CGFloat kPlayerToolBarHeight = 50.0;

@interface JLPlayerView ()
@property (nonatomic, assign) BOOL sliding;
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, copy) NSString * resourceUrlStr;
@property (nonatomic, strong) MPMoviePlayerController *player;
@property (nonatomic, weak) IBOutlet UISlider *playSlider;
@property (nonatomic, weak) IBOutlet UIView *videoPlayView;
@property (nonatomic, weak) IBOutlet UIView *toolBarView;
@property (nonatomic, weak) IBOutlet UIButton *playBtn;
@property (nonatomic, weak) IBOutlet UIButton *scaleBtn;
@property (nonatomic, weak) IBOutlet UILabel *currentTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *totalTimeLabel;
@end

@implementation JLPlayerView

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:self.player];
    
    
    NSLog(@"%@ dealloc", self);
    
}

- (void)removeFromSuperview {
    
    [super removeFromSuperview];
    
    dispatch_cancel(_timer);
    
}

- (void)awakeFromNib {
    
    self.currentTimeLabel.text = [self timeFormatted:0];
    
    self.playSlider.minimumValue = 0;
    self.playSlider.value        = 0;
    
    [self.playSlider setThumbImage:[UIImage imageNamed:kDefaultSliderPotImageName]
                          forState:UIControlStateNormal];
    [self.playSlider setMaximumTrackImage:[UIImage imageNamed:kDefaultSliderBlackImageName]
                                 forState:UIControlStateNormal];
    [self.playSlider setMinimumTrackImage:[UIImage imageNamed:kDefaultSliderRedImageName]
                                 forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStateChange:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.player];
    
   
    
}

- (instancetype)initWithResourceUrlStr:(NSString *)resourceUrlStr Frame:(CGRect)frame {

    self = [super initWithFrame:frame];
    
    if (self) {
        
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"JLPlayerView" owner:self options: nil];
        
        if(arrayOfViews.count < 1){
            return nil;
        }
        
        if(![[arrayOfViews objectAtIndex:0] isKindOfClass:[UIView class]]){
            return nil;
        }
        
        self = [arrayOfViews objectAtIndex:0];
        
        self.resourceUrlStr = resourceUrlStr;
        
        self.frame = frame;
        
    }
    
    return self;

    
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    return [self initWithResourceUrlStr:kDefaultResourceUrlStr Frame:frame];
    
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    _player.view.frame = CGRectMake(0, 0,
                                    self.frame.size.width,
                                    self.frame.size.height - kPlayerToolBarHeight);
    
}

# pragma mark - Setter & Getter
/**
 *  改变横竖屏状态
 *
 *  @param deviceOrientation
 */
- (void)setDeviceOrientation:(JLPlayerOrientation)deviceOrientation {
    
    _deviceOrientation = deviceOrientation;
    
    switch (_deviceOrientation) {
        case JLPlayerOrientationPortrait:
            [self.scaleBtn setImage:[UIImage imageNamed:kScaleBtnMaxImageName] forState:UIControlStateNormal];
            break;
        case JLPlayerOrientationLandscape:
            [self.scaleBtn setImage:[UIImage imageNamed:kScaleBtnMinImageName] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    
}

/**
 *  设置播放资源路径
 *
 *  @param resourceUrlStr
 */
- (void)setResourceUrlStr:(NSString *)resourceUrlStr {
    
    if (_resourceUrlStr == resourceUrlStr) {
        return;
    }
    
    _resourceUrlStr = resourceUrlStr;
    
    _player.contentURL = [[NSURL alloc] initWithString:_resourceUrlStr];
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:[[NSURL alloc] initWithString:_resourceUrlStr] options:opts];
    
    int totalTime = (int)urlAsset.duration.value / urlAsset.duration.timescale;
    
    self.totalTimeLabel.text = [self timeFormatted:totalTime];
    
    self.playSlider.maximumValue = totalTime;
    
}

/**
 *  GCD 计时器
 *
 *  @return
 */
- (dispatch_source_t)timer {
    
    if (!_timer) {
        
        uint64_t interval = 1 * NSEC_PER_SEC;
        dispatch_queue_t queue = dispatch_queue_create("timerQueue", 0);
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        //使用dispatch_source_set_timer函数设置timer参数
        dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), interval, 0);
        //设置回调
        dispatch_source_set_event_handler(_timer, ^(){
            [self updateProgress];
        });
        
    }
    
    return _timer;

}

/**
 *  原生播放器
 *
 *  @return
 */
- (MPMoviePlayerController *)player {
    
    if (!_player) {

        _player = [[MPMoviePlayerController alloc] init];
        _player.contentURL = [[NSURL alloc] initWithString:self.resourceUrlStr ? self.resourceUrlStr: kDefaultResourceUrlStr];
        _player.controlStyle = MPMovieControlStyleNone;
        _player.shouldAutoplay = NO;
        [_player prepareToPlay];
        [_player setScalingMode:MPMovieScalingModeAspectFill];
        
        [self.videoPlayView addSubview:_player.view];
        
        [self.videoPlayView sendSubviewToBack:_player.view];
        
    }
    
    return _player;
    
}

/**
 *  进图条是否处于滑动中
 *
 *  @return 
 */
- (BOOL)sliding {
    
    if (!_sliding) {
        _sliding = NO;
    }
    
    return _sliding;
    
}

# pragma mark - Outlet Action
/**
 *  结束滑动播放进度条
 *
 *  @param sender
 */
- (IBAction)touchUpInSlide:(UISlider *)sender {
    NSLog(@"touch up in");
    self.sliding = NO;
    
    NSTimeInterval slideTime = _player.duration * (double)(sender.value / sender.maximumValue);
    [_player setCurrentPlaybackTime:slideTime];
    
    self.currentTimeLabel.text = [self timeFormatted:slideTime];
    
}

/**
 *  开始滑动播放进度条
 *
 *  @param sender
 */
- (IBAction)touchDownSlide:(UISlider *)sender {
    NSLog(@"touch down");
    if (!self.sliding) {
        self.sliding = YES;
    }
}

/**
 *  播放暂停按钮方法
 *
 *  @param sender
 */
- (IBAction)playOrPuseVideo:(UIButton *)sender {
    
    if ([self.player playbackState] == MPMoviePlaybackStatePaused || [self.player playbackState] == MPMoviePlaybackStateStopped) {
        [self.player play];
    } else {
        [self.player pause];
    }
    
}

/**
 *  横竖屏按钮方法
 *
 *  @param sender
 */
- (IBAction)fullScreen:(UIButton *)sender {
    
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationLandscapeLeft: case UIDeviceOrientationLandscapeRight:
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIInterfaceOrientationPortrait]
                                        forKey:@"orientation"];
            self.deviceOrientation = JLPlayerOrientationPortrait;
            break;
        case UIDeviceOrientationPortrait: case UIDeviceOrientationPortraitUpsideDown:
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft]
                                        forKey:@"orientation"];
            self.deviceOrientation = JLPlayerOrientationLandscape;
            break;
            
        default:
            break;
    }
    
}

# pragma mark - Tool Function
/**
 *  时间格式化方法
 *
 *  @param totalSeconds 当前秒
 *
 *  @return 返回格式“00:00:00”
 */
- (NSString *)timeFormatted:(int)totalSeconds {
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

/**
 *  计时器回调方法 更新进度条和当前播放时间Label的显示
 */
- (void)updateProgress {
    
    int progress = (int)self.player.currentPlaybackTime;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (progress >= 0) {
            
            if (!self.sliding) {
                [self.playSlider setValue:self.player.currentPlaybackTime];
            }
            
            self.currentTimeLabel.text = [self timeFormatted:progress];
        } else {
            if (!self.sliding) {
                [self.playSlider setValue:0];
            }
            
            self.currentTimeLabel.text = [self timeFormatted:0];
            
        }
        
    });
    
}

# pragma mark - Notification
- (void)playStateChange:(NSNotification *)sender {
    
    switch (self.player.playbackState) {
        case MPMoviePlaybackStateStopped:case MPMoviePlaybackStatePaused:case MPMoviePlaybackStateInterrupted:
            self.playBtn.selected = NO;
            dispatch_suspend(self.timer);
            break;
        case MPMoviePlaybackStatePlaying:
            self.playBtn.selected = YES;
            dispatch_resume(self.timer);
            break;
        default:
            break;
    }
    
    [UIApplication sharedApplication].idleTimerDisabled = self.playBtn.selected;
    
    
}

- (void)playbackDidFinish:(NSNotification *)sender {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        int progress = (int)self.player.duration;
        self.currentTimeLabel.text = [self timeFormatted:progress];
        
        self.playBtn.selected = NO;
        
        [self.playSlider setValue:progress];
    });
    
    dispatch_suspend(self.timer);
    
}

@end
