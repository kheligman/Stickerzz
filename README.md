# Stickerzz

A personal wellness habit tracker for iOS — built around the same emoji shorthand you already use in your notes.

## Concept

Most habit apps are either great at streaks *or* great at task planning, but not both. Stickerzz takes a different approach: instead of a task list you get a **calendar of emoji constellations** — the same way you might annotate a journal by hand. Scan a whole month and immediately see patterns. "My skin looks amazing right now... oh, I've been consistent with my red light mask for three weeks."

## Features

| Feature | Detail |
|---|---|
| **Emoji calendar** | Month / 7-day / 3-day views, group-filtered or combined |
| **Routines** | Group habits into named routines (Morning, Evening, Sleep…) |
| **Standalone habits** | Track single habits without wrapping them in a routine |
| **Flexible scheduling** | Daily, N× per week, or specific days of the week |
| **Streak engine** | Daily and weekly streaks; skipped days are transparent (don't break or inflate count) |
| **Luxe habits** | Occasional treatments logged as bonus activity, separate from routine progress |
| **3-state logging** | Done ✓ / Skipped − / Not logged ○ — cycle by tapping |
| **Retroactive logging** | Tap any past calendar day to log or edit |
| **Perfect day indicator** | Gold sparkle ✦ on days where all core habits in a routine were completed |
| **Collapsible Today cards** | Expand inline or navigate to full routine detail |
| **Optional timed sessions** | Stopwatch mode for routines, opt-in via ⏱ |

## Tech Stack

- **Language** — Swift 5.9
- **UI** — SwiftUI (iOS 17+)
- **Persistence** — SwiftData (no Core Data, no third-party dependencies)
- **Minimum deployment** — iOS 17

## Project Structure

```
Stickerzz/
├── Models/
│   ├── HabitGroup.swift       — Routine group (name, color, isStandalone flag)
│   ├── Habit.swift            — Individual habit (emoji, frequency, scheduling)
│   ├── HabitCompletion.swift  — Single log entry (done or skipped)
│   └── FrequencyType.swift    — Enum: daily / weekly / specificDays
├── Utilities/
│   ├── StreakEngine.swift      — Pure streak calculation logic
│   └── Extensions.swift       — Calendar, Color, Array helpers
└── Views/
    ├── Calendar/
    │   ├── CalendarView.swift      — Month/7-day/3-day picker + filter chips
    │   ├── CalendarDayCell.swift   — Month grid cell with emoji constellation
    │   ├── SevenDayView.swift      — Sliding 7-column week view
    │   ├── ThreeDayView.swift      — Sliding 3-column day view with habit names
    │   └── DayDetailSheet.swift    — Day log sheet with 3-state toggles
    ├── Today/
    │   ├── TodayView.swift          — Greeting + progress + routine cards
    │   ├── RoutineCardView.swift    — Collapsible card with inline habit rows
    │   └── RoutineSessionView.swift — Timed session view
    ├── Streaks/
    │   └── StreaksView.swift        — Per-habit streak cards (core habits only)
    ├── Manage/
    │   ├── ManageView.swift               — Routines + Habits sections
    │   ├── GroupEditorView.swift          — Create / edit a routine group
    │   ├── GroupDetailView.swift          — Habit list within a group
    │   ├── HabitEditorView.swift          — Create / edit a habit in a routine
    │   └── StandaloneHabitCreatorView.swift — Create a standalone habit
    └── Shared/
        └── EmojiPickerView.swift   — Categorised emoji grid sheet
```

## Data Model

```
HabitGroup  ──< Habit ──< HabitCompletion
```

- **HabitGroup** holds a named set of habits with a color accent and an `isStandalone` flag (auto-created groups for single habits).
- **Habit** stores the emoji, name, frequency type, scheduling info (`scheduledWeekdays`), and a `isLuxe` flag for bonus habits.
- **HabitCompletion** records a single log entry for a specific calendar day with a `CompletionType` (done or skipped). SwiftData cascade-deletes completions when a habit is deleted.

## Streak Logic

| Frequency | Streak unit | Skip behaviour |
|---|---|---|
| Daily | Consecutive calendar days done | Transparent — skipped days don't break or count |
| Weekly | Consecutive past weeks hitting target count | Skips don't count toward weekly target |
| Specific days | Consecutive scheduled days done | Non-scheduled days transparent; skips transparent |

**Grace period** — if today hasn't been logged yet, the streak doesn't break until the end of the current day (daily) or current week (weekly).

## Building

1. Open `Stickerzz.xcodeproj` in Xcode 15+
2. Select your simulator or device
3. `Cmd+R` to build and run

No package dependencies to resolve.

## Testing

```
Cmd+U  — run all tests
```

Tests cover `StreakEngine` (daily / weekly / specific-day streaks, skip transparency, grace periods, best streak) and `Habit` model methods (completion state, scheduling, makeup-day logic).
