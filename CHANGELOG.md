# Changelog

## [1.0.2] - 2026-09-11
### Added
- Day picker on Today tab — week strip with < > navigation + calendar icon for full date picker
- Completed routines and standalones sink to the bottom of Today view when done
- Day Summary share card — tap ↑ on Today tab to see a shareable recap of the day
- Restore Purchase button always accessible in Manage tab (bottom of list)
- Tags — cross-cutting labels on habits, filterable in Calendar
- MVP habits — mark habits within a routine as Required vs Preferred; routine shows "MVP done ✓" when all required habits are complete
- Group emoji — routines can have an emoji instead of a color swatch
- Group-level streaks in Streaks tab
- Calendar filter sheet — organized by Routines / Habits / Tags / Luxe, replaces horizontal pill row
- 3-day and 7-day calendar views

### Changed
- Calendar grid redesigned: card layout, accent-tinted grid lines, no gray cell borders
- Today cell gets subtle accent fill + accent border (no yellow glow)
- Perfect Day (✨) on share card requires ALL habits across all routines, not just any one
- Calendar compression: when no filter active, shows group emoji once per routine per day
- Preferred habits shown below a dashed divider in routine cards

### Fixed
- Developer Pro toggle now visible on TestFlight (sandboxReceipt detection), not just DEBUG builds

---

## [1.0.0] - Initial build
### Added
- Habit and routine tracking with SwiftData
- Today view with routine cards and inline habit rows
- Calendar (month, week, 3-day views)
- Streaks view with per-habit streak tracking
- Manage tab — create/edit routines and habits
- Luxe (bonus) habits
- Routine timer / session view
- In-app purchase (Pro unlock) via StoreKit 2
- Paywall with restore purchases
