//
//  FlutterViewRegistran.m
//  Runner
//
//  Created by 许大成 on 2023/8/17.
//
#import "FlutterViewRegistran.h"
#import "MyFlutterPlatformView.h"

/*
   Class: MyFlutterPlatformViewFactory
 */
@interface MyFlutterPlatformViewFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messager;

@end

@implementation MyFlutterPlatformViewFactory{
    NSObject<FlutterBinaryMessenger>* _messenger;
}
- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messager {
    self = [super init];
        if (self) {
            _messenger = messager;
        }
        return self;
}
//设置参数的编码方式
-(NSObject<FlutterMessageCodec> *)createArgsCodec{
    return [FlutterStandardMessageCodec sharedInstance];
}

//用来创建 ios 原生view
- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    //args 为flutter 传过来的参数
    MyFlutterPlatformView *textLagel = [[MyFlutterPlatformView alloc] initWithWithFrame:frame viewIdentifier:viewId arguments:args binaryMessenger:_messenger];
    return textLagel;
}
@end

/*
   Class: FlutterViewPlugin
 */
@interface FlutterViewPlugin : NSObject<FlutterPlugin>

@end
@implementation FlutterViewPlugin
+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
    
    //注册插件
    //注册 FlutterIosTextLabelFactory
    //com.flutter_to_native_test_textview 为flutter 调用此  textLabel 的标识
    [registrar registerViewFactory:[[MyFlutterPlatformViewFactory alloc] initWithMessenger:registrar.messenger] withId:@"plugins.flutter.io/custom_platform_view_plugin"];
}
@end

/*
   Class: FlutterViewRegistran
 */
@implementation FlutterViewRegistran
+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry> *)registry {
    [FlutterViewPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterViewPlugin"]];
}
@end
