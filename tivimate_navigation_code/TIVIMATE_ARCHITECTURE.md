# Tivimate Architecture Analysis

## Overview

Tivimate is a heavily obfuscated Android TV IPTV player. This document summarizes the key architectural findings from reverse engineering the app.

---

## App Structure

### Package: `ar.tvplayer.tv`

**Main Components:**
- `MainActivity` - Single activity architecture, landscape, supports PiP
- `ProtectedTvPlayerApplication` - App class with DexGuard protection & signature verification
- Native library `dpboot` for additional protection

**Key Activities:**
| Activity | Purpose |
|----------|---------|
| `MainActivity` | Main IPTV player interface |
| `ReminderPopupActivity` | Program reminder notifications |
| `PlaylistWizardActivity` | Add/configure playlists |
| `TvGuideUrlActivity` | EPG URL configuration |
| `UnlockPremiumActivity` | In-app purchase flow |
| `FilePickerActivity` | Local file browsing |
| `WebViewActivity` | Web content display |

---

## Navigation System

### Core Library: Android Leanback

Tivimate uses **AndroidX Leanback** library for TV navigation:

```
androidx.leanback.widget.*
├── VerticalGridView      - Vertical scrollable grid
├── HorizontalGridView    - Horizontal row carousel
├── GridLayoutManager     - Focus management & D-pad navigation
├── BaseGridView (AbstractC0145) - Common grid behavior
└── ItemBridgeAdapter     - Bridge between data & presenters
```

### Key Navigation Classes

**GridLayoutManager** (`leanback/GridLayoutManager.java`):
- Core D-pad focus handling
- Uses `FocusFinder.getInstance()` for next focus target
- Focus scroll strategies: `FOCUS_SCROLL_ALIGNED`, `FOCUS_SCROLL_ITEM`, `FOCUS_SCROLL_PAGE`
- Handles arrow keys: LEFT(21), RIGHT(22), UP(19), DOWN(20)

**Focus Flow:**
1. `dispatchKeyEvent()` intercepts key press
2. `focusSearch()` finds next focusable view
3. `FocusFinder` calculates nearest neighbor
4. `requestFocus()` on target view
5. `onFocusChanged()` triggers scroll animation

### Key Event Handling

**D-pad Key Codes:**
```java
KEYCODE_DPAD_UP = 19
KEYCODE_DPAD_DOWN = 20
KEYCODE_DPAD_LEFT = 21
KEYCODE_DPAD_RIGHT = 22
KEYCODE_DPAD_CENTER = 23
KEYCODE_ENTER = 66
KEYCODE_BACK = 4
```

**Focus Handling Pattern (from AbstractC3857):**
```java
public boolean dispatchKeyEvent(KeyEvent keyEvent) {
    int keyCode = keyEvent.getKeyCode();
    boolean isNavKey = keyCode == 19 || keyCode == 20 ||
                       keyCode == 21 || keyCode == 22 || keyCode == 23;

    if (isNavKey && isControllerVisible() && !controller.isVisible()) {
        showController(true);
        return true;
    }
    // Handle in child views
    return super.dispatchKeyEvent(keyEvent);
}
```

---

## Player Architecture

### Video Player: ExoPlayer (Media3)

**Core Classes:**
- `C4644` - ExoPlayer implementation (`p392` package)
- `C4683` - ExoPlayerInternal (playback thread)
- `C4654` - Message handling

**Player View Hierarchy:**
```
CustomPlayerView (extends AbstractC3857)
├── AspectRatioFrameLayout (f14943) - Video container
│   └── SurfaceView/TextureView (f14926) - Video surface
├── SubtitleView (f14948) - Subtitle overlay
├── ImageView (f14939) - Artwork/thumbnail
├── FrameLayout (f14950) - Overlay container
├── FrameLayout (f14923) - Ad overlay
└── C3860 (f14949) - Player controls
```

### Player Controls (C3860)

**UI Components:**
- Play/Pause button
- Forward/Rewind buttons
- SeekBar/progress
- Time displays (current/duration)
- Fullscreen toggle
- Settings popup
- RecyclerView (f15016) - track/chapter selection

**Control Visibility:**
```java
setControllerShowTimeoutMs(int ms)  // Auto-hide delay
setControllerAutoShow(boolean)       // Show on playback state change
setControllerHideOnTouch(boolean)    // Hide when tapping away
```

---

## UI Layout Patterns

### XML Patterns

**Focusable Container:**
```xml
<FrameLayout
    android:focusable="true"
    android:focusableInTouchMode="true"
    android:descendantFocusability="afterDescendants">
```

**Grid Views:**
```xml
<androidx.leanback.widget.HorizontalGridView
    android:focusable="true"
    android:focusableInTouchMode="true"
    android:clipChildren="false"
    android:clipToPadding="false" />
```

### Focus Settings

```java
// Grid setup
setDescendantFocusability(FOCUS_AFTER_DESCENDANTS)  // 262144
setPreserveFocusAfterLayout(false)
setChildrenDrawingOrderEnabled(true)  // Draw focused on top

// Scroll behavior
setWindowAlignment(WINDOW_ALIGN_BOTH_EDGE)  // 3
setFocusScrollStrategy(FOCUS_SCROLL_ALIGNED)  // 0
```

---

## Adapter Pattern

### Leanback Presenter Pattern

```
C0108 (ItemBridgeAdapter extension)
├── ViewOnKeyListenerC0103   - Key event handling
├── ViewOnFocusChangeListenerC0089 - Focus changes
├── ViewOnClickListenerC0083 - Click events
└── C0134 - Editor action listener (search)
```

**ViewHolder Binding:**
1. `onCreateViewHolder()` - Inflate layout
2. `onBindViewHolder()` - Bind data
3. Set focus/key listeners on views
4. Handle selection state

---

## Settings System

Uses **AndroidX Preference** with Leanback styling:
- `LeanbackListPreferenceDialogFragment` (C1434)
- `VerticalGridView` for preference lists
- Custom dialogs for multi-select

**Settings Categories:**
- Playlists (add/edit/delete)
- TV Guide sources
- Appearance (logos, themes)
- Recordings folder
- Channel groups

---

## File Structure (Extracted)

```
tivimate_navigation_code/
├── leanback/
│   ├── GridLayoutManager.java (73KB) - Core navigation
│   ├── BaseGridView.java - Abstract grid
│   ├── VerticalGridView.java
│   ├── HorizontalGridView.java
│   └── [130+ leanback files]
├── player_ui/
│   ├── AbstractC3857.java - Player view base
│   ├── C3860.java - Player controls
│   └── C3869.java - Surface callbacks
├── exoplayer/
│   ├── C4644.java - ExoPlayer impl
│   ├── C4654.java - Message handling
│   └── C4683.java - Playback internal
├── adapters/
│   ├── C0108.java - Item bridge adapter
│   ├── ViewOnKeyListenerC0103.java
│   └── ViewOnFocusChangeListenerC0089.java
├── app_key_handlers/
│   ├── AbstractActivityC4410.java - Base activity
│   └── ViewOnKeyListenerC0860.java - Key listener
├── recyclerview/
│   └── [RecyclerView sources]
└── xml_layouts/
    └── [54 layout files]
```

---

## Key Takeaways for Plezy Implementation

1. **Use AndroidX Leanback** for TV navigation - battle-tested for D-pad
2. **GridLayoutManager** handles focus management automatically
3. **FOCUS_AFTER_DESCENDANTS** is crucial for nested focusable views
4. **Player controls** should auto-show on navigation key press
5. **FocusFinder** is the Android system service for focus calculation
6. **setPreserveFocusAfterLayout(false)** ensures fresh focus after layout changes
7. **clipChildren=false** allows focused items to expand beyond bounds
8. **ExoPlayer (Media3)** is the standard for video playback

---

## Libraries Used

- AndroidX Leanback 1.0+
- AndroidX Media3 (ExoPlayer) 1.8.0
- Moshi (JSON parsing)
- Glide + OkHttp (image loading)
- Firebase Crashlytics
- Google Play Billing

---

*Analysis performed on Tivimate v5.x APK*
