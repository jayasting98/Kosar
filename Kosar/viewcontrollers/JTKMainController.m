//
//  JTKMainController.m
//  Kosar
//
//  Created by ByteDance on 1/6/22.
//

#import "JTKMainController.h"

#import "JTKAuthService.h"
#import "JTKAuthenticationModalController.h"
#import "JTKContainerSchemeHelper.h"
#import "JTKCreatePostModalController.h"
#import "JTKHomeController.h"
#import "JTKModalHandler.h"

#import "Masonry.h"
#import "MaterialBottomNavigation.h"
#import "MaterialBottomNavigation+Theming.h"
#import "MaterialButtons.h"
#include <MaterialComponents/MDCContainerScheme.h>

static NSString * const kHomeTabBarItemTitle = @"Home";

static NSString * const kHomeTabBarItemIcon = @"timeline-timeline_symbol";
static NSString * const kFloatingActionButtonIcon = @"add-add_symbol";

static CGFloat const kFloatingActionButtonMarginBottom = 16;
static CGFloat const kFloatingActionButtonMarginRight = 16;
static CGSize const kFloatingActionButtonSize = {56, 56};

@interface JTKCreatePostModalHandler : JTKModalHandler<JTKMainController *, JTKCreatePostModalController *>

@end

@interface JTKCreatePostModalHandler () <JTKCreatePostModalDelegate>

@end

@implementation JTKCreatePostModalHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalViewController = [[JTKCreatePostModalController alloc] init];
        self.modalViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        self.modalViewController.modalDelegate = self;
    }
    return self;
}

- (void)reactToCloseButtonTap {
    [self dismissAnimated:YES withCompletionHandler:nil];
}

- (void)reactToCreateButtonTapWithInvalidPost {
    NSLog(@"Reacting to invalid post.");
}

- (void)reactToCreateButtonTapWithValidPost {
    [self dismissAnimated:YES withCompletionHandler:nil];
}

@end

@interface JTKAuthenticationModalHandler : JTKModalHandler<JTKMainController *, JTKAuthenticationModalController *>

@end

@interface JTKAuthenticationModalHandler () <JTKAuthenticationStateObserver>

@end

@implementation JTKAuthenticationModalHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalViewController = [[JTKAuthenticationModalController alloc] init];
        self.modalViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)reactToSignIn {
    [self dismissAnimated:YES withCompletionHandler:nil];
}

- (void)reactToSignOut {
    [self presentAnimated:YES withCompletionHandler:nil];
}

@end

@interface JTKMainController () <MDCBottomNavigationBarDelegate>

@property (nonatomic) JTKAuthenticationModalHandler *authenticationModalHandler;
@property (nonatomic) JTKCreatePostModalHandler *createPostModalHandler;

@property (nonatomic) MDCBottomNavigationBar *bottomNavigationBar;
@property (nonatomic) MDCFloatingButton *floatingActionButton;

@end

@implementation JTKMainController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupAuthenticationModalHandler];
    [self setupCreatePostModalHandler];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self buildBottomNavigationBar];
    [self setupTabViewControllers];
    [self buildFloatingActionButton];
}

- (void)setupAuthenticationModalHandler {
    self.authenticationModalHandler = [[JTKAuthenticationModalHandler alloc] init];
    self.authenticationModalHandler.presentingViewController = self;
}

- (void)setupCreatePostModalHandler {
    self.createPostModalHandler = [[JTKCreatePostModalHandler alloc] init];
    self.createPostModalHandler.presentingViewController = self;
}

- (void)setupTabViewControllers {
    self.viewControllers = @[
        [self createTabWithViewController:[[JTKHomeController alloc] init]],
    ];
}

- (void)buildBottomNavigationBar {
    self.bottomNavigationBar = [[MDCBottomNavigationBar alloc] init];
    [self.view addSubview:self.bottomNavigationBar];
    self.bottomNavigationBar.titleVisibility = MDCBottomNavigationBarTitleVisibilitySelected;
    self.bottomNavigationBar.alignment = MDCBottomNavigationBarAlignmentJustifiedAdjacentTitles;
    UITabBarItem *homeItem = [[UITabBarItem alloc] initWithTitle:kHomeTabBarItemTitle
                                                           image:[UIImage imageNamed:kHomeTabBarItemIcon]
                                                             tag:0];
    self.bottomNavigationBar.items = @[homeItem];
    self.bottomNavigationBar.selectedItem = homeItem;
    self.bottomNavigationBar.delegate = self;
}

- (void)layoutBottomNavigationBar {
    CGSize size = [self.bottomNavigationBar sizeThatFits:self.view.bounds.size];
    size.height += self.view.safeAreaInsets.bottom;
    [self.bottomNavigationBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(size);
        make.left.right.and.bottom.equalTo(self.view);
    }];
}

- (void)buildFloatingActionButton {
    self.floatingActionButton = [MDCFloatingButton floatingButtonWithShape:MDCFloatingButtonShapeDefault];
    [self.view addSubview:self.floatingActionButton];
    UIImage *floatingActionButtonImage = [UIImage imageNamed:kFloatingActionButtonIcon];
    [self.floatingActionButton setImage:floatingActionButtonImage forState:UIControlStateNormal];
    [self.floatingActionButton addTarget:self
                                  action:@selector(presentCreatePostModal)
                        forControlEvents:UIControlEventTouchUpInside];
}

- (void)layoutFloatingActionButton {
    UIEdgeInsets margin = self.view.safeAreaInsets;
    margin.right += kFloatingActionButtonMarginRight;
    [self.floatingActionButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(kFloatingActionButtonSize);
        make.bottom.equalTo(self.bottomNavigationBar.mas_top).with.offset(-kFloatingActionButtonMarginBottom);
        make.right.equalTo(self.view.mas_right).with.offset(-margin.right);
    }];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self layoutBottomNavigationBar];
    [self layoutFloatingActionButton];
}

- (void)adjustAdditionalSafeAreaInsetsDueToBottomNavigationBar {
    UIEdgeInsets newSafeArea = self.additionalSafeAreaInsets;
    newSafeArea.bottom += self.bottomNavigationBar.frame.size.height - self.tabBar.frame.size.height;
    self.selectedViewController.additionalSafeAreaInsets = newSafeArea;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self adjustAdditionalSafeAreaInsetsDueToBottomNavigationBar];
    [self enableReactingToSignIn];
    [self presentAuthenticationModalIfNecessary];
}

- (void)enableReactingToSignIn {
    [[JTKAuthService sharedInstance] addAuthenticationStateObserver:self.authenticationModalHandler];
}

- (void)presentAuthenticationModalIfNecessary {
    if ([[JTKAuthService sharedInstance] isSignedIn]) {
        return;
    }
    [self.authenticationModalHandler presentAnimated:YES withCompletionHandler:nil];
}

- (UINavigationController *)createTabWithViewController:(UIViewController *)viewController {
    UINavigationController *tabViewController = [
        [UINavigationController alloc] initWithRootViewController:viewController
    ];
    return tabViewController;
}

- (void)bottomNavigationBar:(MDCBottomNavigationBar *)bottomNavigationBar didSelectItem:(UITabBarItem *)item {
    self.selectedIndex = item.tag;
}

- (void)presentCreatePostModal {
    [self.createPostModalHandler presentAnimated:YES withCompletionHandler:nil];
}

@end
