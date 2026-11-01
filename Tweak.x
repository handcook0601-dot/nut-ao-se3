#import <UIKit/UIKit.h>
#import <spawn.h>

extern char **environ;

// Cửa sổ trong suốt chỉ nhận cảm ứng tại vị trí nút nổi hoặc bảng menu
@interface SE3OverlayWindow : UIWindow
@property (nonatomic, strong) UIButton *floatButton;
@property (nonatomic, strong) UIView *menuPanel;
@end

@implementation SE3OverlayWindow

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.floatButton && !self.floatButton.hidden) {
        CGPoint btnPoint = [self convertPoint:point toView:self.floatButton];
        if ([self.floatButton pointInside:btnPoint withEvent:event]) {
            return YES;
        }
    }
    if (self.menuPanel && !self.menuPanel.hidden) {
        CGPoint menuPoint = [self convertPoint:point toView:self.menuPanel];
        if ([self.menuPanel pointInside:menuPoint withEvent:event]) {
            return YES;
        }
    }
    return NO;
}

@end

// Controller quản lý nút điều khiển ảo trên SpringBoard (tối ưu cho màn hình 4.7" 375x667 của iPhone SE 3)
@interface SE3FloatController : NSObject
@property (nonatomic, strong) SE3OverlayWindow *overlayWindow;
+ (instancetype)sharedInstance;
- (void)setupWindowIfNeeded;
@end

@implementation SE3FloatController

+ (instancetype)sharedInstance {
    static SE3FloatController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SE3FloatController alloc] init];
    });
    return instance;
}

- (UIWindowScene *)activeWindowScene {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]] &&
            (scene.activationState == UISceneActivationStateForegroundActive ||
             scene.activationState == UISceneActivationStateForegroundInactive)) {
            return (UIWindowScene *)scene;
        }
    }
    return (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.anyObject;
}

- (void)setupWindowIfNeeded {
    if (self.overlayWindow) return;

    UIWindowScene *scene = [self activeWindowScene];
    CGRect bounds = [UIScreen mainScreen].bounds; // 375 x 667 trên iPhone SE 3

    if (scene) {
        self.overlayWindow = [[SE3OverlayWindow alloc] initWithWindowScene:scene];
        self.overlayWindow.frame = bounds;
    } else {
        self.overlayWindow = [[SE3OverlayWindow alloc] initWithFrame:bounds];
    }

    self.overlayWindow.windowLevel = UIWindowLevelStatusBar + 100.0;
    self.overlayWindow.backgroundColor = [UIColor clearColor];

    UIViewController *rootVC = [[UIViewController alloc] init];
    rootVC.view.backgroundColor = [UIColor clearColor];
    self.overlayWindow.rootViewController = rootVC;

    // Tạo nút điều khiển nổi (50x50 pt)
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(bounds.size.width - 62.0, bounds.size.height * 0.4, 50.0, 50.0);
    btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
    btn.layer.cornerRadius = 25.0;
    btn.layer.borderWidth = 1.5;
    btn.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.4].CGColor;
    [btn setTitle:@"SE3" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [btn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [btn addGestureRecognizer:pan];

    [rootVC.view addSubview:btn];
    self.overlayWindow.floatButton = btn;

    // Tạo bảng menu tiện ích
    UIView *panel = [[UIView alloc] initWithFrame:CGRectMake((bounds.size.width - 220.0) / 2.0, (bounds.size.height - 180.0) / 2.0, 220.0, 180.0)];
    panel.backgroundColor = [[UIColor colorWithWhite:0.12 alpha:1.0] colorWithAlphaComponent:0.92];
    panel.layer.cornerRadius = 16.0;
    panel.layer.borderWidth = 1.0;
    panel.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    panel.hidden = YES;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 12, 220, 24)];
    title.text = @"iPhone SE 3 (A15) Menu";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:14.0];
    title.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:title];

    UIButton *respringBtn = [self actionButtonWithTitle:@"Respring (sbreload)" frame:CGRectMake(20, 50, 180, 38) action:@selector(doRespring)];
    [panel addSubview:respringBtn];

    UIButton *uicacheBtn = [self actionButtonWithTitle:@"Làm mới Icon (uicache)" frame:CGRectMake(20, 96, 180, 38) action:@selector(doUICache)];
    [panel addSubview:uicacheBtn];

    UIButton *closeBtn = [self actionButtonWithTitle:@"Đóng" frame:CGRectMake(20, 140, 180, 30) action:@selector(toggleMenu)];
    [panel addSubview:closeBtn];

    [rootVC.view addSubview:panel];
    self.overlayWindow.menuPanel = panel;

    self.overlayWindow.hidden = NO;
}

- (UIButton *)actionButtonWithTitle:(NSString *)title frame:(CGRect)frame action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = frame;
    b.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    b.layer.cornerRadius = 8.0;
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)toggleMenu {
    self.overlayWindow.menuPanel.hidden = !self.overlayWindow.menuPanel.hidden;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *btn = gesture.view;
    CGPoint translation = [gesture translationInView:btn.superview];
    btn.center = CGPointMake(btn.center.x + translation.x, btn.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:btn.superview];

    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGRect bounds = [UIScreen mainScreen].bounds;
        CGFloat targetX = (btn.center.x < bounds.size.width / 2.0) ? 32.0 : (bounds.size.width - 32.0);
        CGFloat clampedY = MAX(50.0, MIN(bounds.size.height - 50.0, btn.center.y));
        [UIView animateWithDuration:0.2 animations:^{
            btn.center = CGPointMake(targetX, clampedY);
        }];
    }
}

- (void)runCmd:(const char *)path args:(const char *const *)argv {
    pid_t pid;
    posix_spawn(&pid, path, NULL, NULL, (char *const *)argv, environ);
}

- (void)doRespring {
    const char *args[] = {"sbreload", NULL};
    [self runCmd:"/var/jb/usr/bin/sbreload" args:args];
}

- (void)doUICache {
    const char *args[] = {"uicache", "-a", NULL};
    [self runCmd:"/var/jb/usr/bin/uicache" args:args];
    [self toggleMenu];
}

@end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[SE3FloatController sharedInstance] setupWindowIfNeeded];
    });
}

%end
