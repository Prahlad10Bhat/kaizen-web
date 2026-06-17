# Changelog

All notable changes to this project will be documented in this file.

## [1.0.9] - 2026-06-07

### Added
- **App Tour**: Added bottom sidebar items (Feedback, Settings, Profile) to the Navigation & Sidebar tour.
- **App Tour**: The App Tour menu now dynamically shows a "This Page" option that launches the tour based on the currently active screen.
- **UI**: Added a high-contrast floating banner to politely notify users if a specific page does not have an interactive tour available yet.

### Changed
- **App Tour**: The Home Dashboard tour now properly highlights the Focus Timer instead of the old clock card.
- **UI**: The voice command microphone button now clearly indicates its muted state with a red crossed-out icon, and uses a green icon when actively listening. The button background is now fully transparent until hovered.
- **App Tour**: Replaced the static list of tours in the App Tour dropdown with a simpler, contextual "This Page" option.

### Fixed
- **App Tour**: Fixed an issue where clicking on a highlighted target would cause the tour to double-skip and jump past steps.
- **App Tour**: The Sidebar tour now automatically expands the sidebar if it was collapsed before starting.
- **App Tour**: Tour popups for items at the very bottom of the screen (Settings, Profile) now shift upwards to prevent getting cut off by the window frame.

