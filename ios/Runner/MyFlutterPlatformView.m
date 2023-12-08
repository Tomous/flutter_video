//
//  MyFlutterPlatformView.m
//  Runner
//
//  Created by 许大成 on 2023/8/15.
//

#import "MyFlutterPlatformView.h"
#import "VideoPlayer.h"
@interface MyFlutterPlatformView ()

@property (nonatomic, strong) VideoPlayer *videoPlayer;

@end
@implementation MyFlutterPlatformView{
    //FlutterIosTextLabel 创建后的标识
    int64_t _viewId;
    UILabel * _uiLabel;
    //消息回调
    FlutterMethodChannel* _channel;
    CGRect _frame;
    id _args;
}

//在这里只是创建了一个UILabel
-(instancetype)initWithWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger{
    if ([super init]) {
        if (frame.size.width==0) {
            frame=CGRectMake(frame.origin.x, frame.origin.y, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width*9/18);
        }
        _frame = frame;
        _args = args;
        _viewId = viewId;
    
    }
    return self;
    
}



- (nonnull UIView *)view {
    UIView * playerView = [[UIView alloc] initWithFrame:_frame];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->_videoPlayer = [VideoPlayer playerWithVideoURL:[NSURL URLWithString:self->_args[@"videoUrl"]] playerView:playerView playerSuperView:playerView.superview];
        self->_videoPlayer.playerEndAction = VideoPlayerEndActionStop;
        [self->_videoPlayer play];
        
    });
    return playerView;
}
- (void)dealloc {
    [self.videoPlayer pause];
    [self.videoPlayer destroyPlayer];
}
@end
