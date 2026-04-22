# High Performance Feed

A Flutter demo app that shows an infinite image feed backed by Supabase.

## What it includes

- Infinite scrolling with page size 10
- Pull to refresh
- Optimistic likes with debounce and rollback on failure
- Hero transition from feed item to detail view
- Lightweight image loading for smoother scrolling

## Tech stack

- Flutter
- Riverpod
- Supabase

## Local setup

1. Install dependencies

```bash
flutter pub get
```

2. Create a .env file in the project root

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-publishable-anon-key
```

3. Run

```bash
flutter run
```

## Riverpod state management (short version)

I kept state in two focused Riverpod pieces so UI and network logic stay clean:

- Feed state (`feedProvider`): owns the post list, current page, loading flag, and hasMore flag.
- Like state (`likeProvider`): applies instant optimistic like updates, then syncs in the background with debounce.

Why this setup worked well:

- UI reads one source of truth, so scrolling/refresh/likes stay consistent.
- Refresh can safely reset feed state without mixing old and new pages.
- Rapid like taps still feel instant, but backend calls stay controlled.

## How I verified RepaintBoundary and memCacheWidth

I verified both in Flutter DevTools during fast scrolling tests on real content.

RepaintBoundary verification:

1. Opened DevTools Performance view and enabled repaint rainbow.
2. Fast-scrolled the feed.
3. Confirmed repaints were mostly isolated to individual cards instead of cascading across the full list.

memCacheWidth (`cacheWidth`) verification:

1. Confirmed feed images use thumbnail URLs and pass `cacheWidth` based on screen width.
2. Opened DevTools Memory view and scrolled through many posts.
3. Checked that memory stayed stable without large decoded-image spikes.

Result:

- Scrolling remained smooth under heavy card shadows.
- No obvious memory blow-up during long scroll sessions.