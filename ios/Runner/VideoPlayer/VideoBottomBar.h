//
//  VideoBottomBar.h
//  Runner
//
//  Created by 许大成 on 2023/8/17.
//
#ifndef VideoBottomBar_h
#define VideoBottomBar_h
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol VideoBottomBarDelegate <NSObject>

- (void)videoBottomBarDidClickPlayPauseBtn;
- (void)videoBottomBarDidClickChangeScreenBtn;
- (void)videoBottomBarDidTapSlider:(UISlider *)slider withTap:(UITapGestureRecognizer *)tap;
- (void)videoBottomBarChangingSlider:(UISlider *)slider;
- (void)videoBottomBarDidEndChangeSlider:(UISlider *)slider;

@end

@interface VideoBottomBar : UIView

@property (nonatomic, weak) id<VideoBottomBarDelegate> delegate;

@property (nonatomic, strong) UIButton *playPauseBtn;
@property (nonatomic, strong) UIButton *changeScreenBtn;

@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *totalTimeLabel;

@property (nonatomic, strong) UISlider *playingProgressSlider;

@property (nonatomic, strong) UIProgressView *cacheProgressView;

+ (instancetype)videoBottomBar;

@end

NS_ASSUME_NONNULL_END
#endif
