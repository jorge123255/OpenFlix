# Home Screen Redesign — Design Spec

**Date:** 2026-04-15
**Scope:** tvOS home screen (XfinityHomeView)
**Approach:** Structured redesign — add Live TV + DVR rails, reorder hierarchy, unify card styles

## Data Layer

Wire into `XfinityHomeView`:
- Add `@StateObject private var dvrViewModel = DVRViewModel()`
- On `.task`, call `dvrViewModel.loadRecordings()` and `dvrViewModel.loadDownloadJobs()` alongside existing `viewModel.loadHomeContent()` and `liveTVViewModel.loadChannels()`
- Call `liveTVViewModel.refreshNowPlaying()` after channels load so each channel gets its `nowPlaying` program populated
- Refresh now-playing every 60s via the existing `liveRefreshTick` mechanism
- No new API calls needed — all data already flows through `LiveTVViewModel` and `DVRViewModel`

## Rail Hierarchy (tvOS)

1. **Hero** — library featured (existing `tvCompactHeroSection`, unchanged)
2. **Continue Watching** — existing rail, unchanged
3. **On Now** — NEW: channel cards with logo + live program title + progress bar
4. **Recently Recorded** — NEW: wide cards from `dvrViewModel.justRecorded`, with recording status badge
5. **Currently Recording indicator** — red pulsing dot + show title in a floating badge at top-right of the hero section, visible only when `dvrViewModel.currentlyRecording` is non-empty. Tap navigates to DVR tab.
6. **Recently Added** — existing rail, unchanged
7. **Top Picks** — existing rail, unchanged
8. **Recommended For You** — existing rail, unchanged
9. **Movies** — existing rail, unchanged
10. **TV Shows** — existing rail, unchanged
11. **Hubs** — existing ForEach, unchanged

### Dead "View All" Fix
Remove the non-functional `Text("View All")` from rails that have no view-all destination. Change `tvHomeRow` helper `showViewAll` default to `false`, only pass `true` where a navigation target exists.

## New Card Components

### TVLiveNowCard (On Now rail)
- Layout: 16:9 landscape card, same dimensions as `TVCompactWideCard` (340x192)
- Top: blurred channel artwork or gradient background
- Center: channel logo (from `channel.logo`), scaled to fit
- Bottom: gradient overlay with live program title (from `channel.nowPlaying.title`), channel name, and a thin progress bar showing how far through the current program (computed from `nowPlaying.startTime`/`endTime`)
- Focus behavior: same as existing cards — `isFocused` scale 1.03, white border, shadow
- Tap: tune to channel (existing `onPlayChannel` flow)
- Badge: small red "LIVE" pill in top-left corner

### TVRecentlyRecordedCard (Recently Recorded rail)
- Layout: same as `TVCompactWideCard` (340x192)
- Top: recording artwork (from `recording.art ?? recording.thumb`)
- Bottom: gradient with title, subtitle (episode info if available), and channel name
- Status badge: small pill in top-right — "Recorded" (green), "Recording" (red pulsing), or download status
- Focus behavior: same pattern as existing cards
- Tap: open recording detail (existing `selectedItem` + `showMediaDetail` flow)

### Currently Recording Indicator
- Floating badge overlaid on the hero section's top-right corner
- Red pulsing dot + "Recording: [title]" text
- Only visible when `dvrViewModel.currentlyRecording` is non-empty
- Tapping navigates to DVR tab (not a separate sheet)

Both new cards reuse the exact same focus animation, corner radius (18pt continuous), border width, and shadow parameters as the existing `TVCompactWideCard`.

## Edge Cases

- **No live TV channels**: On Now rail doesn't render (existing `if !items.isEmpty` pattern)
- **Channels but no now-playing data**: Show channel card with logo + name, no program title or progress bar. LIVE badge still shows.
- **No DVR recordings**: Recently Recorded rail and recording indicator both don't render
- **Now-playing refresh failure**: Keep stale data from last successful refresh. 60s timer keeps retrying.
- **DVR load failure**: recordings stay empty, rails just don't appear
- **Mixed provider recordings**: `justRecorded` includes local + provider recordings. Card shows provider route label (e.g., "Cloud DVR") when applicable.

## Files to Modify

- `Views/Home/XfinityHomeView.swift` — add DVRViewModel, new rails, new card structs, reorder tvContentView, fix View All, add recording indicator
- No other files need modification — data sources already exist in LiveTVViewModel and DVRViewModel