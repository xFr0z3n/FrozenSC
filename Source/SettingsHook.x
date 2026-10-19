#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "Prefs/FrozenSCDiscordSettingsController.h"

// FrozenSC's settings screen (long-press in the SoundCloud tab bar) is a UITableView whose data
// source is NexaSCSettingsViewController. Its rows come from a nested array:
// settingsSections[section][row] = item dictionary with "title" / "icon" / "type".
//
// We append our own one-row section. The table is driven entirely by that array, so the row renders
// natively. Taps dispatch on item["type"] and an unknown type does nothing there, so we catch ours
// in didSelect and open the Discord RPC screen.

static NSString *const kFrozenSCDiscordRowType = @"frozensc_discord_rpc";

// Same {title, icon, type} shape as the built-in action rows ("Support Me", "Contact Me")
static NSDictionary *FrozenSCDiscordRowItem(void) {
    return @{
        @"title": @"Discord RPC",
        @"icon": @"antenna.radiowaves.left.and.right",
        @"type": kFrozenSCDiscordRowType
    };
}

// Topmost view controller of the active window: the settings screen is a child inside the
// player popup, not a navigation stack, so we present from the top instead.
static UIViewController *FrozenSCTopViewController(UIViewController *fallback) {
    UIViewController *root = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]] ||
            scene.activationState != UISceneActivationStateForegroundActive)
            continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) { root = window.rootViewController; break; }
        }
        if (root) break;
    }
    UIViewController *top = root ?: fallback;
    while (top.presentedViewController)
        top = top.presentedViewController;
    return top;
}

%group FrozenSCSettings

%hook NexaSCSettingsViewController

- (void)setupSettingsData {
    %orig;

    NSArray *sections = [self valueForKey:@"settingsSections"];
    if (![sections isKindOfClass:[NSArray class]])
        return;

    // setupSettingsData can run again on refresh: add the row once
    for (id section in sections) {
        if (![section isKindOfClass:[NSArray class]]) continue;
        for (id item in (NSArray *)section) {
            if ([item isKindOfClass:[NSDictionary class]] &&
                [((NSDictionary *)item)[@"type"] isEqual:kFrozenSCDiscordRowType])
                return;
        }
    }

    NSMutableArray *updated = [sections mutableCopy];
    [updated addObject:@[ FrozenSCDiscordRowItem() ]];
    [self setValue:[updated copy] forKey:@"settingsSections"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sections = [self valueForKey:@"settingsSections"];
    NSDictionary *item = nil;
    if ([sections isKindOfClass:[NSArray class]] && indexPath.section < (NSInteger)sections.count) {
        id section = sections[indexPath.section];
        if ([section isKindOfClass:[NSArray class]] && indexPath.row < (NSInteger)[(NSArray *)section count])
            item = ((NSArray *)section)[indexPath.row];
    }

    if ([item isKindOfClass:[NSDictionary class]] &&
        [item[@"type"] isEqual:kFrozenSCDiscordRowType]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[FrozenSCDiscordSettingsController new]];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        [FrozenSCTopViewController(self) presentViewController:nav animated:YES completion:nil];
        return;
    }

    %orig;
}

%end

%end

// FrozenSC's dylib may load after this one, so hook its settings once its class exists:
// right away if it's already loaded, otherwise when the app has finished launching.
static BOOL gSettingsHooked = NO;

static void FrozenSCHookSettingsIfReady(void) {
    if (gSettingsHooked || !objc_getClass("NexaSCSettingsViewController"))
        return;
    gSettingsHooked = YES;
    %init(FrozenSCSettings);
}

%ctor {
    FrozenSCHookSettingsIfReady();
    if (!gSettingsHooked) {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            FrozenSCHookSettingsIfReady();
        }];
    }
}
