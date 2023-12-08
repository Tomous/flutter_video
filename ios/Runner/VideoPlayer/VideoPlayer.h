//
//  VideoPlayer.h
//  Runner
//
//  Created by 许大成 on 2023/8/17.
//
#ifndef VideoPlayer_h
#define VideoPlayer_h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VideoPlayerState) {
    VedioPlayerStateFailed,
    VideoPlayerStateBuffering,
    VideoPlayerStatePlaying,
    VideoPlayerStatePaused,
    VideoPlayerStateFinished,
    VideoPlayerStateStopped
};

typedef NS_ENUM(NSInteger, VideoPlayerEndAction) {
    VideoPlayerEndActionStop,
    VideoPlayerEndActionLoop,
    VideoPlayerEndActionDestroy
};

@interface VideoPlayer : NSObject

@property (nonatomic, assign, readonly) VideoPlayerState playerState;

/**
 The action when the video play to end, default is VideoPlayerEndActionStop.
 */
@property (nonatomic, assign) VideoPlayerEndAction playerEndAction;

/**
 Creates and returns a video player with video's URL, playerView and playerSuperView.

 @param videoURL        The URL of the video.
 @param playerView      The view which you want to display the video.
 @param playerSuperView The playerView's super view.
 @return A newly video player.
 */
+ (instancetype)playerWithVideoURL:(NSURL *)videoURL playerView:(UIView *)playerView playerSuperView:(UIView *)playerSuperView;

- (void)play;
- (void)pause;
- (void)resume;

- (void)destroyPlayer;

@end

NS_ASSUME_NONNULL_END
#endif
