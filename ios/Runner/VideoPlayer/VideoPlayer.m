//
//  VideoPlayer.m
//  Runner
//
//  Created by 许大成 on 2023/8/17.
//

#import "VideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Masonry.h"
#import "PlayerLayerView.h"
#import "VideoBottomBar.h"

static NSString * const VideoPlayerItemStatusKeyPath           = @"status";
static NSString * const VideoPlayerItemLoadedTimeRangesKeyPath = @"loadedTimeRanges";

@interface VideoPlayer ()<UIGestureRecognizerDelegate, VideoBottomBarDelegate>
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, assign, readwrite) VideoPlayerState playerState;
@property (nonatomic, assign) UIInterfaceOrientation currentOrientation;
@property (nonatomic, strong) UIView *touchView;
@property (nonatomic, strong) VideoBottomBar *bottomBar;
@property (nonatomic, assign) CGPoint touchBeginPoint;
@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, assign) BOOL isDragingSlider;
@property (nonatomic, assign) BOOL isManualPaused;
@property (nonatomic, assign) NSTimeInterval videoDuration;
@property (nonatomic, assign) NSTimeInterval videoCurrent;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, weak) UIView *playerView;
@property (nonatomic, weak) UIView *playerSuperView;
@property (nonatomic, strong) PlayerLayerView *playerLayerView;
@property (nonatomic, assign) CGRect  playerViewOriginalRect;
@property (nonatomic, strong) UIButton *replayBtn;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) NSObject *playbackTimeObserver;

@end

@implementation VideoPlayer

- (void)dealloc {

    [self destroyPlayer];

    NSLog(@"%s", __func__);
}

#pragma mark - Lazy Load

- (PlayerLayerView *)playerLayerView {

    if (!_playerLayerView) {
        _playerLayerView = [[PlayerLayerView alloc] init];
    }
    return _playerLayerView;
}

- (VideoBottomBar *)bottomBar {

    if (!_bottomBar) {
        _bottomBar = [VideoBottomBar videoBottomBar];
        _bottomBar.delegate = self;
        _bottomBar.userInteractionEnabled = NO;
    }
    return _bottomBar;
}

- (UIActivityIndicatorView *)activityIndicatorView {

    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] init];
    }
    return _activityIndicatorView;
}

- (UIView *)touchView {

    if (!_touchView) {
        _touchView = [[UIView alloc] init];
        _touchView.backgroundColor = [UIColor clearColor];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchViewTapAction:)];
        tap.delegate = self;
        [_touchView addGestureRecognizer:tap];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(touchViewPanAction:)];
        pan.delegate = self;
        [_touchView addGestureRecognizer:pan];

        _touchView.userInteractionEnabled = NO;
    }
    return _touchView;
}

- (UIButton *)replayBtn {

    if (!_replayBtn) {
        _replayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_replayBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
        [_replayBtn addTarget:self action:@selector(replayAction) forControlEvents:UIControlEventTouchUpInside];
        _replayBtn.hidden = NO;
    }
    return _replayBtn;
}



#pragma mark - Init Methods
+ (instancetype)playerWithVideoURL:(NSURL *)videoURL playerView:(UIView *)playerView playerSuperView:(UIView *)playerSuperView {
    return [[VideoPlayer alloc]initWithVideoURL:videoURL playerView:playerView playerSuperView:playerSuperView];
}
- (instancetype)initWithVideoURL:(NSURL *)videoURL playerView:(UIView *)playerView playerSuperView:(UIView *)playerSuperView {
    if (self = [super init]) {
        _videoURL = videoURL;
        _playerState = VideoPlayerStateBuffering;
        _playerEndAction = VideoPlayerEndActionStop;

        _playerView = playerView;
        _playerView.backgroundColor = [UIColor blackColor];
        _playerView.userInteractionEnabled = YES;

        _playerViewOriginalRect = playerView.frame;
        _playerSuperView = playerSuperView;

        [self setupSubViews];
        [self setupOrientation];
        
    }
    return self;
}

- (void)setupSubViews {

    __weak typeof(self) weakSelf = self;

    [_playerView addSubview:self.playerLayerView];
    [self.playerLayerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
        make.left.mas_equalTo(0);
    }];

    [_playerView addSubview:self.bottomBar];
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.bottom.equalTo(weakSelf.playerView);
        make.right.mas_equalTo(0);
        make.height.mas_equalTo(44);
    }];

    [_playerView addSubview:self.activityIndicatorView];
    [self.activityIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.playerLayerView);
        make.centerY.equalTo(weakSelf.playerLayerView);
        make.width.mas_equalTo(44);
        make.height.mas_equalTo(44);
    }];

    [_playerView addSubview:self.touchView];
    [self.touchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsMake(0, 0, 40, 0));
    }];

    [_playerView addSubview:self.replayBtn];
    [self.replayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(60, 60));
        make.center.equalTo(weakSelf.playerView);
    }];

}

- (void)setupOrientation {

    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortrait:
            _currentOrientation = UIInterfaceOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            _currentOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            _currentOrientation = UIInterfaceOrientationLandscapeRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            _currentOrientation = UIInterfaceOrientationPortraitUpsideDown;
            break;
        default:
            break;
    }

    // Notice: Must set the app only support portrait orientation.
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark - Monitor Methods

- (void)orientationDidChange {

    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            [self changeToOrientation:UIInterfaceOrientationPortrait];
            break;
        case UIDeviceOrientationLandscapeLeft:
            [self changeToOrientation:UIInterfaceOrientationLandscapeRight];
            break;
        case UIDeviceOrientationLandscapeRight:
            [self changeToOrientation:UIInterfaceOrientationLandscapeLeft];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [self changeToOrientation:UIInterfaceOrientationPortraitUpsideDown];
            break;
        default:
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:VideoPlayerItemStatusKeyPath]) {
        NSLog(@"VideoPlayerItemStatusKeyPath");
        switch (playerItem.status) {
            case AVPlayerStatusReadyToPlay:
            {
                NSLog(@"AVPlayerStatueadyToPlay");
                [self.activityIndicatorView stopAnimating];
                [self.player pause];
                _playerState = VideoPlayerStatePaused;
                
                self.bottomBar.userInteractionEnabled = YES;
                self.touchView.userInteractionEnabled = YES; // prevents the crash that caused by dragging before the video has not load successfully
                
                _videoDuration = playerItem.duration.value / playerItem.duration.timescale; // total time of the video
                self.bottomBar.totalTimeLabel.text = [self formatTimeWith:(long)ceil(_videoDuration)];
                self.bottomBar.playingProgressSlider.minimumValue = 0.0;
                self.bottomBar.playingProgressSlider.maximumValue = _videoDuration;
                
                __weak __typeof(self)weakSelf = self;
                _playbackTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
                    __strong __typeof(weakSelf) strongSelf = weakSelf;
                    if (weakSelf.isDragingSlider) {
                        return;
                    }
                    if (strongSelf.activityIndicatorView.isAnimating) {
                        [strongSelf.activityIndicatorView stopAnimating];
                    }
                    if (!strongSelf.isManualPaused) {
                        strongSelf.playerState = VideoPlayerStatePlaying;
                    }
                    CGFloat currentTime = playerItem.currentTime.value / playerItem.currentTime.timescale;
                    strongSelf.bottomBar.currentTimeLabel.text = [strongSelf formatTimeWith:(long)ceil(currentTime)];
                    [strongSelf.bottomBar.playingProgressSlider setValue:currentTime animated:YES];
                    strongSelf.videoCurrent = currentTime;
                    if (strongSelf.videoCurrent > strongSelf.videoDuration) {
                        strongSelf.videoCurrent = strongSelf.videoDuration;
                    }
                }];
                break;
            }
                
            case AVPlayerStatusFailed:
            {
                // Loading video error which usually a resource issue.
                NSLog(@"AVPlayerStatueadyToPlay");
                NSLog(@"player error: %@", _player.error);
                NSLog(@"playerItem error: %@", _playerItem.error);
                [self.activityIndicatorView stopAnimating];
                _playerState = VedioPlayerStateFailed;
                [self destroyPlayer];
                break;
            }
                
            case AVPlayerStatusUnknown:
            {
                NSLog(@"AVPlayerStatusUnknown");
                break;
            }
        }
    }
    
    if ([keyPath isEqualToString:VideoPlayerItemLoadedTimeRangesKeyPath]) {
        NSLog(@"VideoPlayerItemLoadedTimeRangesKeyPath");
        CMTimeRange timeRange = [playerItem.loadedTimeRanges.firstObject CMTimeRangeValue]; // buffer area
        NSTimeInterval timeBuffered = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration); // buffer progress
        NSTimeInterval timeTotal= CMTimeGetSeconds(playerItem.duration);
        [self.bottomBar.cacheProgressView setProgress:timeBuffered / timeTotal animated:YES];
    }
}

- (void)playerItemDidPlayToEnd:(NSNotification *)notification {
    
    _playerState = VideoPlayerStateFinished;
    
    switch (_playerEndAction) {
        case VideoPlayerEndActionStop:
            self.bottomBar.hidden = NO;
            self.replayBtn.hidden = NO;
            break;
        case VideoPlayerEndActionLoop:
            [self replayAction];
            break;
        case VideoPlayerEndActionDestroy:
            [self destroyPlayer];
            break;
    }
}

- (void)applicationWillResignActive {
    
    if (!_playerItem) {
        return;
    }
    [self.player pause];
    _playerState = VideoPlayerStatePaused;
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
}

- (void)applicationDidBecomeActive {
    
    if (!_playerItem) {
        return;
    }
    if (_isManualPaused) {
        return;
    }
    [self.player play];
    _playerState = VideoPlayerStatePlaying;
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
}

- (void)replayAction {

    [self seekToTimeWithSeconds:0];
    self.bottomBar.hidden = NO;
    self.replayBtn.hidden = YES;
    _playerState = VideoPlayerStatePlaying;
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];

    [self timingHideBottomBarTime];
}

#pragma mark - Player Methods

- (void)setupPlayer {
    
    _playerItem = [AVPlayerItem playerItemWithURL:_videoURL];
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    [(AVPlayerLayer *)self.playerLayerView.layer setPlayer:_player];
    
    [_playerItem addObserver:self forKeyPath:VideoPlayerItemStatusKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:VideoPlayerItemLoadedTimeRangesKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self.activityIndicatorView startAnimating];
}

- (void)play {

    if (!_videoURL) {
        return;
    }
    [self setupPlayer];
}

- (void)pause {

    if (!_playerItem) {
        return;
    }
    [_player pause];

    _isManualPaused = YES;
    _playerState = VideoPlayerStatePaused;
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
}

- (void)resume {

    if (!_playerItem) {
        return;
    }
    [_player play];

    _isManualPaused = NO;
    _playerState = VideoPlayerStatePlaying;
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
}

- (void)destroyPlayer {

    if (!_player) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (_playerState == VideoPlayerStatePlaying) {
        [_player pause];
    }

    [_player removeTimeObserver:_playbackTimeObserver];
    _player = nil;
    _playbackTimeObserver = nil;

    [_playerItem removeObserver:self forKeyPath:VideoPlayerItemStatusKeyPath];
    [_playerItem removeObserver:self forKeyPath:VideoPlayerItemLoadedTimeRangesKeyPath];
    _playerItem = nil;

    [_playerView removeFromSuperview];
}

#pragma mark - Orientation Methods

- (void)changeToOrientation:(UIInterfaceOrientation)orientation {

    if (_currentOrientation == orientation) {
        return;
    }
    _currentOrientation = orientation;

    [_playerView removeFromSuperview];
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            [_playerSuperView addSubview:_playerView];
            __weak typeof(self) weakSelf = self;
            
            [_playerView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(CGRectGetMinY(weakSelf.playerViewOriginalRect));
                make.left.mas_equalTo(CGRectGetMinX(weakSelf.playerViewOriginalRect));
                make.width.mas_equalTo(CGRectGetWidth(weakSelf.playerViewOriginalRect));
                make.height.mas_equalTo(CGRectGetHeight(weakSelf.playerViewOriginalRect));
            }];
            [_bottomBar.changeScreenBtn setImage:[UIImage imageNamed:@"full_screen"] forState:UIControlStateNormal];
            break;
        }
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            [[UIApplication sharedApplication].keyWindow addSubview:_playerView];
            [_playerView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(@([UIScreen mainScreen].bounds.size.height));
                make.height.equalTo(@([UIScreen mainScreen].bounds.size.width));
                make.center.equalTo([UIApplication sharedApplication].keyWindow);
            }];
            [_bottomBar.changeScreenBtn setImage:[UIImage imageNamed:@"small_screen"] forState:UIControlStateNormal];
            break;
        }
        default:
            break;
    }
    [UIView animateWithDuration:0.5 animations:^{
        self->_playerView.transform = [self getTransformWithOrientation:orientation];
    }];

}

- (CGAffineTransform)getTransformWithOrientation:(UIInterfaceOrientation)orientation{

    if (orientation == UIInterfaceOrientationPortrait) {
        [self updateToVerticalOrientation];
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        [self updateToHorizontalOrientation];
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        [self updateToHorizontalOrientation];
        return CGAffineTransformMakeRotation(M_PI_2);
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        [self updateToVerticalOrientation];
        return CGAffineTransformMakeRotation(M_PI);
    }
    return CGAffineTransformIdentity;
}

- (void)updateToVerticalOrientation {
    
    _isFullScreen = NO;
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)updateToHorizontalOrientation {
    
    _isFullScreen = YES;
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

#pragma mark - UIGestureRecognizerDelegate

- (void)touchViewTapAction:(UITapGestureRecognizer *)tap {
    
    if (self.bottomBar.hidden) {
        [self showTopBottomBar];
    } else {
        [self hideTopBottomBar];
    }
}

- (void)touchViewPanAction:(UIPanGestureRecognizer *)pan {
    
    [self showTopBottomBar];
}

#pragma mark - VideoBottomBarDelegate

- (void)videoBottomBarDidClickPlayPauseBtn {
    
    if (!_playerItem) {
        return;
    }
    switch (_playerState) {
        case VideoPlayerStatePlaying:
            [self pause];
            break;
        case VideoPlayerStatePaused:
            [self resume];
            break;
        default:
            break;
    }
    
    [self timingHideBottomBarTime];
}

- (void)videoBottomBarDidClickChangeScreenBtn {
    
    if (_isFullScreen) {
        [self changeToOrientation:UIInterfaceOrientationPortrait];
    } else {
        [self changeToOrientation:UIInterfaceOrientationLandscapeRight];
    }
    
    [self timingHideBottomBarTime];
}

- (void)videoBottomBarDidTapSlider:(UISlider *)slider withTap:(UITapGestureRecognizer *)tap {
    
    CGPoint touchPoint = [tap locationInView:slider];
    float value = (touchPoint.x / slider.frame.size.width) * slider.maximumValue;
    self.bottomBar.currentTimeLabel.text = [self formatTimeWith:(long)ceil(value)];
    [self seekToTimeWithSeconds:value];
    
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    
    [self timingHideBottomBarTime];
}

- (void)videoBottomBarChangingSlider:(UISlider *)slider {
    
    _isDragingSlider = YES;
    
    self.bottomBar.currentTimeLabel.text = [self formatTimeWith:(long)ceil(slider.value)];
    
    [self timingHideBottomBarTime];
}

- (void)videoBottomBarDidEndChangeSlider:(UISlider *)slider {
    
    // The delay is to prevent the sliding point from jumping.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->_isDragingSlider = NO;
    });
    
    self.bottomBar.currentTimeLabel.text = [self formatTimeWith:(long)ceil(slider.value)];
    [self seekToTimeWithSeconds:slider.value];
    
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    
    [self timingHideBottomBarTime];
}

#pragma mark - Assist Methods

- (NSString *)formatTimeWith:(long)time {

    NSString *formatTime = nil;
    if (time < 3600) {
        formatTime = [NSString stringWithFormat:@"%02li:%02li", lround(floor(time / 60.0)), lround(floor(time / 1.0)) % 60];
    } else {
        formatTime = [NSString stringWithFormat:@"%02li:%02li:%02li", lround(floor(time / 3600.0)), lround(floor(time % 3600) / 60.0), lround(floor(time / 1.0)) % 60];
    }
    return formatTime;
}

- (void)seekToTimeWithSeconds:(CGFloat)seconds {
    
    if (_playerState == VideoPlayerStateStopped) {
        return;
    }
    seconds = MAX(0, seconds);
    seconds = MIN(seconds, _videoDuration);
    [self.player pause];
    [self.player seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        [self.player play];
        self->_isManualPaused = NO;
        self->_playerState = VideoPlayerStatePlaying;
        if (!self->_playerItem.isPlaybackLikelyToKeepUp) {
            self->_playerState = VideoPlayerStateBuffering;
            [self.activityIndicatorView startAnimating];
        }
    }];
}

- (NSTimeInterval)videoCurrentTimeWithTouchPoint:(CGPoint)touchPoint {

    float videoCurrentTime = _videoCurrent + 99 * ((touchPoint.x - _touchBeginPoint.x) / [UIScreen mainScreen].bounds.size.width);

    if (videoCurrentTime > _videoDuration) {
        videoCurrentTime = _videoDuration;
    }
    if (videoCurrentTime < 0) {
        videoCurrentTime = 0;
    }
    return videoCurrentTime;
}

- (void)showTopBottomBar {

    if (_playerState != VideoPlayerStatePlaying) {
        return;
    }
    self.bottomBar.hidden = NO;
    [self timingHideBottomBarTime];
}

- (void)hideTopBottomBar {

    if (_playerState != VideoPlayerStatePlaying) {
        return;
    }
    self.bottomBar.hidden = YES;
}

- (void)timingHideBottomBarTime {

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideTopBottomBar) object:nil];
    [self performSelector:@selector(hideTopBottomBar) withObject:nil afterDelay:5.0];
}


@end
