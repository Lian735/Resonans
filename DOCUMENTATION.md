# Resonans codebase overview

This document describes the structure and responsibilities of the Resonans iOS app so contributors can quickly navigate the code.

## Top-level layout
- `ResonansApp.swift` boots the SwiftUI application, wires the shared `ContentViewModel`, and applies the user-selected appearance via `@AppStorage`.
- `Views/` contains the SwiftUI screens: the tab shell (`ContentView`), home dashboard, tools catalog, settings, and onboarding flow.
- `Models/` defines lightweight data types such as tool definitions, app storage keys, and recently exported items.
- `DataSources/` holds singleton managers for tool registration and cache/recents persistence.
- `Utilities/`, `Components/`, and `OSFeatures/` provide reusable UI building blocks, styling constants, and platform integrations (e.g., haptics).

## Application flow
- **Entry point:** `ResonansApp` constructs `ContentView` inside a `WindowGroup`, injects `ContentViewModel`, and restores the persisted appearance. On launch it preloads favorite tools from `UserDefaults` so the UI can render with correct badges and sections immediately.
- **Tabs and routing:** `ContentView` drives the three-tab layout (Home, Tools, Settings) using `@Published` selection in `ContentViewModel`. It also presents onboarding as a full-screen cover until the user completes it, persisting choices for accent color and guided tips.

## Data and state
- **Tool registry:** `ToolManager` is a singleton that lazily loads the available `ToolItem` definitions from hard-coded identifiers, exposing them via a published array for SwiftUI bindings.
- **Tool metadata:** `ToolIdentifier` enumerates the supported tools and builds the corresponding `ToolItem` (title, subtitle, icon, gradient, beta flag, default favorite) plus the navigation destination view for each tool.
- **Caching and recents:** `CacheManager` centralizes cache directory creation, clearing, and persistence of recent tools and conversion outputs. It stores recent conversions as `RecentItem` values, ensures file existence, trims history, and posts an update notification after writes.
- **Session state:** `ContentViewModel` tracks the active tab, selected tool, favorites set, and recently used tool identifiers. It exposes helper methods to hydrate favorites from storage and derive the recent tool list from identifiers.

## Feature surfaces
- **Home dashboard:** `HomeDashboardView` welcomes the user, links to tool browsing, and highlights favorites and recent tools. Buttons update the shared view model to open the selected tool tab and remember the last-used tool for quick reentry.
- **Tools catalog:** `ToolsView` lists tools with search and favorite prioritization. `ToolOverview` renders each card, handles favoriting persistence, and routes to the tool-specific destination while tracking recents in the shared view model.
- **Onboarding:** `OnboardingFlowView` walks users through feature highlights, favorite selection, workflow preference, and optional guided tips. Completion returns the chosen favorites and tips flag to `ContentView` to persist and dismiss onboarding.
- **Settings:** `SettingsView` allows appearance/accent selection, toggles haptics/sounds/experimental flags, reopens onboarding, and triggers cache clearing through `CacheManager`. Experimental toggles are surfaced when enabled.

## UI and platform utilities
- **Styling:** `StyleConstants.swift` (via `AppStyle`) centralizes spacing, corner radii, stroke/fill opacities, and background helpers used across views.
- **Haptics:** `HapticsManager` wraps `UIImpactFeedbackGenerator`, `UISelectionFeedbackGenerator`, and `UINotificationFeedbackGenerator`, gating feedback based on the persisted haptics setting.
- **Shared components:** Reusable views such as `AppCard`, `GlassButton`, `ToolIconView`, shimmer/mesh gradients, and swipe-dismiss helpers live under `Utilities/` and `Components/`, keeping feature screens lean.

## Persistence keys and options
- `AppStorageKey` and related enums (e.g., `Appearance`, `AccentColorOption`) define the keys used with `@AppStorage` for appearance, accent color, onboarding completion, guided tips, haptics, sounds, and experimental feature flags. Settings and onboarding views rely on these to stay in sync with user defaults.
