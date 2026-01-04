# Product Requirements Document (PRD)
# FragranceStackios - Fragrance Collection & Recommendation App

**Version:** 1.0
**Author:** Stuart Nealy Jr.
**Date:** January 2026
**Platform:** iOS, iPadOS, macOS, visionOS

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Vision & Goals](#2-product-vision--goals)
3. [Target Users](#3-target-users)
4. [Features & Requirements](#4-features--requirements)
5. [Technical Architecture](#5-technical-architecture)
6. [Data Models](#6-data-models)
7. [User Interface Design](#7-user-interface-design)
8. [Implementation Roadmap](#8-implementation-roadmap)
9. [Success Metrics](#9-success-metrics)
10. [Future Enhancements](#10-future-enhancements)

---

## 1. Executive Summary

**FragranceStackios** is a sophisticated iOS application designed for fragrance enthusiasts ("fragheads") to manage their perfume collections, track fragrance wears, receive personalized recommendations, and discover optimal fragrance layering combinations.

### Problem Statement

Fragrance collectors face several challenges:
- **Collection Management:** Difficulty tracking owned fragrances, purchase details, and remaining amounts
- **Decision Fatigue:** Choosing the right fragrance for specific occasions, weather, and moods
- **Layering Complexity:** Understanding which fragrances work well together
- **Usage Tracking:** No way to log and analyze wearing patterns and preferences

### Solution

FragranceStackios provides an all-in-one platform that:
- Organizes fragrance collections with detailed metadata
- Delivers smart, context-aware recommendations using a multi-factor scoring algorithm
- Features a Layering Lab for exploring and creating fragrance combinations
- Tracks wear history with comprehensive analytics

---

## 2. Product Vision & Goals

### Vision Statement

*To be the essential companion app for fragrance enthusiasts, transforming how people discover, manage, and experience their fragrance collections.*

### Primary Goals

| Goal | Description | Priority |
|------|-------------|----------|
| **Collection Management** | Provide comprehensive fragrance cataloging with personal customization | P0 |
| **Smart Recommendations** | Deliver context-aware suggestions based on occasion, weather, and preferences | P0 |
| **Wear Tracking** | Enable detailed logging and analytics of fragrance usage | P1 |
| **Layering Discovery** | Facilitate exploration of fragrance combinations | P1 |
| **User Personalization** | Allow customization of preferences and settings | P2 |

### Success Criteria

- Users can add and manage 100+ fragrances without performance degradation
- Recommendation engine achieves >80% user satisfaction rate
- Daily active engagement with wear logging feature
- Positive user feedback on layering compatibility scoring

---

## 3. Target Users

### Primary Persona: The Fragrance Enthusiast

**Demographics:**
- Age: 25-45
- Gender: All genders
- Income: Middle to upper-middle class
- Tech-savvy iOS users

**Characteristics:**
- Owns 10-100+ fragrances
- Passionate about discovering new scents
- Considers fragrance selection important for different occasions
- Active in fragrance communities (Fragrantica, Reddit r/fragrance)
- Interested in clone fragrances and value propositions

**Pain Points:**
- Forgets which fragrances work for which occasion
- Struggles to decide what to wear daily
- Wants to explore layering but lacks guidance
- No centralized way to track collection value and usage

### Secondary Persona: The Casual Collector

**Characteristics:**
- Owns 5-20 fragrances
- Looking to make better purchasing decisions
- Values recommendations and guidance
- Less technical knowledge about fragrance notes and families

---

## 4. Features & Requirements

### 4.1 Fragrance Collection Management

#### Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| COL-001 | Browse fragrances in a searchable, sortable grid/list view | P0 | Done |
| COL-002 | Search by fragrance name or brand | P0 | Done |
| COL-003 | Filter by signature fragrances | P0 | Done |
| COL-004 | Sort by name, brand, rating, or times worn | P0 | Done |
| COL-005 | Add custom fragrances with full metadata | P0 | Done |
| COL-006 | View detailed fragrance information including note pyramid | P0 | Done |
| COL-007 | Track purchase price, date, and bottle size | P1 | Done |
| COL-008 | Track remaining amount and calculate cost per wear | P1 | Done |
| COL-009 | Mark fragrances as signature or favorite | P1 | Done |
| COL-010 | Add personal notes and ratings | P1 | Done |

#### Fragrance Metadata

```
Required Fields:
- Name (String)
- Brand (String)
- Concentration (EDT, EDP, Parfum, Cologne, EDC)

Optional Fields:
- Fragrance Family (Citrus, Woody, Oriental, Floral, Fresh, Aromatic, Fougère, Chypre, Gourmand)
- Gender (Masculine, Feminine, Unisex)
- Release Year
- Clone Original Reference
- External IDs (Fragrantica, Parfumo)
- Personal Rating (1-5 stars)
- Personal Notes
```

### 4.2 Intelligent Recommendation Engine

#### Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REC-001 | Generate recommendations based on occasion | P0 | Done |
| REC-002 | Factor in time of day (morning, afternoon, evening, night) | P0 | Done |
| REC-003 | Consider weather conditions and temperature | P0 | Done |
| REC-004 | Allow vibe/mood selection | P1 | Done |
| REC-005 | Display confidence score for recommendations | P0 | Done |
| REC-006 | Provide explanation for why a fragrance was recommended | P1 | Done |
| REC-007 | Show alternative suggestions | P1 | Done |
| REC-008 | Quick-log recommended fragrance wear | P0 | Done |

#### Recommendation Algorithm

```
Score = (Season_Match × 0.3) + (Occasion_Match × 0.3) +
        (Performance_Score × 0.2) + (User_Preference × 0.2)

Scoring Components:
- Season Match: Based on fragrance's season suitability scores (1-10)
- Occasion Match: Based on fragrance's occasion suitability scores
- Performance Score: Weighted combination of longevity, projection, sillage
- User Preference: Personal rating or community average rating

Bonuses:
- Signature fragrance: +15%
- Favorite fragrance: +10%

Penalties:
- Same brand as last recommendation: -10%
- Same family as last recommendation: -5%
```

#### Predefined Scenarios

1. **Work Morning** - Professional, light projection
2. **Date Night** - Romantic, moderate-to-heavy projection
3. **Casual Weekend** - Relaxed, versatile
4. **Formal Event** - Sophisticated, refined
5. **Night Out** - Bold, statement-making

### 4.3 Wear Logging & Analytics

#### Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| LOG-001 | Log fragrance wear with date and time | P0 | Done |
| LOG-002 | Select occasion for each wear | P0 | Done |
| LOG-003 | Record weather and temperature | P1 | Done |
| LOG-004 | Track compliments received | P1 | Done |
| LOG-005 | Rate satisfaction for each wear | P1 | Done |
| LOG-006 | Add optional notes | P2 | Done |
| LOG-007 | Support layering logs (multiple fragrances) | P1 | Done |
| LOG-008 | View wear history with filtering | P0 | Done |
| LOG-009 | Display statistics (most worn, variety score, monthly count) | P1 | Done |
| LOG-010 | Quick-log from fragrance detail view | P0 | Done |

#### Wear Log Data

```
Required:
- Fragrance Reference
- Date
- Time of Day (Morning, Afternoon, Evening, Night)
- Occasion (Office, Date, Casual, Formal, Club)

Optional:
- Weather Condition
- Temperature
- Compliments Count
- Satisfaction Rating (1-5)
- Personal Notes
- Layered With (Fragrance Reference)
```

### 4.4 Fragrance Layering Lab

#### Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| LAY-001 | Browse pre-defined layering combinations | P0 | Done |
| LAY-002 | Filter combinations by season | P1 | Done |
| LAY-003 | Sort by compatibility score | P1 | Done |
| LAY-004 | View combination details with ratio and application order | P0 | Done |
| LAY-005 | Calculate compatibility for custom fragrance pairs | P0 | Done |
| LAY-006 | Display compatibility score with visual indicator | P0 | Done |
| LAY-007 | Suggest optimal ratio between fragrances | P1 | Done |
| LAY-008 | Save custom combinations | P1 | Done |
| LAY-009 | Log layering combination wear | P1 | Done |

#### Compatibility Algorithm

The layering compatibility score is calculated based on:
- Fragrance family harmony (some families blend better than others)
- Note overlap analysis
- Performance balance (longevity and projection matching)
- Community validation data

#### Combination Metadata

```
- Fragrance 1 Reference
- Fragrance 2 Reference
- Compatibility Score (1-10)
- Ratio (e.g., 60:40)
- Application Order (Simultaneous, Fragrance 1 First, Fragrance 2 First)
- Best Seasons (Array)
- Best Occasions (Array)
- User Notes
```

### 4.5 Dashboard

#### Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| DASH-001 | Display today's recommendation with confidence score | P0 | Done |
| DASH-002 | Show quick statistics (collection size, monthly wears) | P0 | Done |
| DASH-003 | Display most worn fragrance | P1 | Done |
| DASH-004 | Show recent wear logs | P1 | Done |
| DASH-005 | Provide quick navigation to recommendation engine | P0 | Done |

### 4.6 Profile & Settings

#### Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| PRO-001 | Display user name and greeting | P1 | Done |
| PRO-002 | Set location for weather integration | P1 | Done |
| PRO-003 | Configure favorite occasions | P1 | Done |
| PRO-004 | Select temperature unit (°C/°F) | P2 | Done |
| PRO-005 | View collection statistics and family breakdown | P1 | Done |
| PRO-006 | Toggle dark mode | P2 | Partial |
| PRO-007 | Export/backup data | P2 | Planned |
| PRO-008 | Display app version | P2 | Done |

---

## 5. Technical Architecture

### 5.1 Technology Stack

| Layer | Technology | Justification |
|-------|------------|---------------|
| **UI Framework** | SwiftUI | Modern declarative UI, native performance, cross-platform |
| **Persistence** | SwiftData | Apple's native ORM, type-safe, reactive queries |
| **Concurrency** | Swift async/await | Modern, clean async code |
| **Architecture** | MVVM | SwiftUI-native, clear separation of concerns |
| **Platforms** | iOS 17+, iPadOS 17+, macOS 14+, visionOS 1+ | Broad Apple ecosystem support |

### 5.2 Project Structure

```
FragranceStackios/
├── App/
│   └── FragranceStackiosApp.swift    # App entry point, data seeding
├── Models/
│   ├── Fragrance.swift               # Core fragrance model
│   ├── Note.swift                    # Fragrance note model
│   ├── FragranceNote.swift           # Many-to-many join table
│   ├── UserFragrance.swift           # User-specific fragrance data
│   ├── WearLog.swift                 # Wear history records
│   ├── LayeringCombination.swift     # Layering pairs
│   ├── Recommendation.swift          # Generated recommendations
│   └── FragranceMetrics.swift        # Performance metrics
├── Services/
│   ├── RecommendationEngine.swift    # Smart recommendation logic
│   └── WeatherService.swift          # Weather data integration
├── Views/
│   ├── MainTabView.swift             # 5-tab navigation
│   ├── Dashboard/                    # Home screen views
│   ├── Collection/                   # Fragrance library views
│   ├── Recommender/                  # Recommendation views
│   ├── LayeringLab/                  # Layering feature views
│   ├── WearLog/                      # Wear tracking views
│   └── Profile/                      # Settings views
├── Theme/
│   └── AppTheme.swift                # Design system
└── ContentView.swift                 # Legacy (unused)
```

### 5.3 Data Flow Architecture

```
┌─────────────────────────────────────────────────────────┐
│                       SwiftUI Views                      │
│  (Dashboard, Collection, Recommender, LayeringLab, etc) │
└─────────────────────┬───────────────────────────────────┘
                      │ @Query / @Environment(\.modelContext)
                      ▼
┌─────────────────────────────────────────────────────────┐
│                     SwiftData Layer                      │
│              (ModelContainer, ModelContext)              │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                    Services Layer                        │
│        (RecommendationEngine, WeatherService)            │
└─────────────────────────────────────────────────────────┘
```

### 5.4 State Management

| State Type | Mechanism | Use Case |
|------------|-----------|----------|
| **View State** | `@State` | Local UI state (selections, toggles) |
| **Database Context** | `@Environment(\.modelContext)` | CRUD operations |
| **Reactive Queries** | `@Query` | Auto-updating data lists |
| **Navigation** | `NavigationStack` + `NavigationLink` | Screen transitions |

---

## 6. Data Models

### 6.1 Entity Relationship Diagram

```
┌─────────────┐       ┌───────────────┐       ┌──────────┐
│  Fragrance  │◄──────│ FragranceNote │──────►│   Note   │
│             │   1:N │ (Join Table)  │ N:1   │          │
│  - id       │       │ - noteType    │       │ - id     │
│  - name     │       │ - intensity   │       │ - name   │
│  - brand    │       └───────────────┘       │ - category│
│  - conc.    │                               └──────────┘
│  - family   │
│  - gender   │       ┌───────────────────┐
└──────┬──────┘       │ FragranceMetrics  │
       │         1:1  │  - longevity      │
       ├─────────────►│  - projection     │
       │              │  - sillage        │
       │              │  - seasonScores   │
       │              │  - occasionScores │
       │              └───────────────────┘
       │
       │         1:N  ┌───────────────────┐
       ├─────────────►│  UserFragrance    │
       │              │  - purchaseDate   │
       │              │  - purchasePrice  │
       │              │  - bottleSize     │
       │              │  - remaining      │
       │              │  - rating         │
       │              │  - isSignature    │
       │              └─────────┬─────────┘
       │                        │
       │                        │ 1:N
       │                        ▼
       │         1:N  ┌───────────────────┐
       └─────────────►│     WearLog       │
                      │  - dateWorn       │
                      │  - timeOfDay      │
                      │  - occasion       │
                      │  - weather        │
                      │  - satisfaction   │
                      └───────────────────┘

┌─────────────┐       ┌───────────────────┐
│  Fragrance  │◄──────│LayeringCombination│──────►┌───────────┐
│     (1)     │   N:1 │ - compatibility   │ N:1   │ Fragrance │
└─────────────┘       │ - ratio           │       │    (2)    │
                      │ - applicationOrder│       └───────────┘
                      └───────────────────┘

┌─────────────┐       ┌───────────────────┐
│  Fragrance  │◄──────│  Recommendation   │
└─────────────┘   N:1 │  - occasion       │
                      │  - weather        │
                      │  - confidence     │
                      │  - wasAccepted    │
                      └───────────────────┘
```

### 6.2 Core Model Specifications

#### Fragrance

| Property | Type | Description |
|----------|------|-------------|
| id | UUID | Primary key |
| name | String | Fragrance name |
| brand | String | Manufacturer/house |
| concentration | FragranceConcentration | EDT, EDP, Parfum, etc. |
| fragranceFamily | FragranceFamily? | Olfactory family |
| gender | FragranceGender? | Target gender |
| releaseYear | Int? | Year of release |
| isClone | Bool | Clone indicator |
| cloneOf | Fragrance? | Original if clone |
| cloneAccuracy | Double? | Clone similarity % |
| priceRange | String? | Price tier |
| fragranticaId | String? | External reference |
| parfumoId | String? | External reference |
| imageUrl | URL? | Bottle image |
| notes | [FragranceNote] | Note pyramid |
| metrics | FragranceMetrics? | Performance data |
| userFragrances | [UserFragrance] | User-specific data |

#### Enumerations

```swift
enum FragranceConcentration: String, Codable {
    case edt = "EDT"
    case edp = "EDP"
    case parfum = "Parfum"
    case cologne = "Cologne"
    case edc = "EDC"
}

enum FragranceFamily: String, Codable {
    case citrus, woody, oriental, floral
    case fresh, aromatic, fougere, chypre, gourmand
}

enum FragranceGender: String, Codable {
    case masculine, feminine, unisex
}

enum NoteType: String, Codable {
    case top, heart, base
}

enum NoteCategory: String, Codable {
    case citrus, floral, woody, spicy
    case fruity, green, aquatic, gourmand
    case herbal, animalic, resinous, powdery
}

enum TimeOfDay: String, Codable {
    case morning, afternoon, evening, night
}

enum Occasion: String, Codable {
    case office, date, casual, formal, club
}

enum ApplicationOrder: String, Codable {
    case simultaneous, fragrance1First, fragrance2First
}
```

---

## 7. User Interface Design

### 7.1 Design System

#### Color Palette

| Color | Hex Code | Usage |
|-------|----------|-------|
| App Navy | #1a1a2e | Primary text, headers |
| App Gold | #d4af37 | Accent, CTAs, ratings |
| App Cream | #faf8f5 | Backgrounds, cards |
| White | #ffffff | Card backgrounds |
| Semantic colors | System | Success, warning, error states |

#### Typography

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| App Title | 28pt | Bold | Section headers |
| App Headline | 20pt | Semibold | Subsection headers |
| App Subheadline | 16pt | Medium | Labels |
| App Body | 16pt | Regular | Body text |
| App Caption | 12pt | Regular | Secondary text |
| App Stat | 32pt | Rounded | Metrics display |

### 7.2 Navigation Structure

```
┌─────────────────────────────────────────────────────────┐
│                    Tab Bar (5 Tabs)                      │
├────────────┬────────────┬───────────┬──────────┬────────┤
│  Dashboard │ Collection │ Recommend │ Layering │Profile │
│     🏠     │     📚    │     ✨    │    🧪    │   👤   │
└────────────┴────────────┴───────────┴──────────┴────────┘
```

### 7.3 Key Screen Flows

#### Collection Flow
```
CollectionView ──► FragranceDetailView ──► QuickLogSheet
       │                    │
       └► AddFragranceView  └► LayeringLabView (Find Layers)
```

#### Recommendation Flow
```
ContextSelectionView ──► RecommendationResultsView ──► QuickLogSheet
(occasion, time, weather)        (top picks, alternatives)
```

#### Layering Lab Flow
```
LayeringLabView (Browse) ──► CombinationDetailView ──► LogComboSheet
        │
        └► LayeringCalculatorView ──► SaveComboSheet
                (Calculate mode)
```

### 7.4 Component Library

| Component | Description | Usage |
|-----------|-------------|-------|
| FragranceCard | Card with image, brand, name, rating | Collection grid |
| StarRatingView | 5-star display | Ratings throughout |
| BadgeStyle | Pill-shaped tag | Seasons, occasions |
| LoadingView | Spinner indicator | Async operations |
| EmptyStateView | Icon + message | Empty lists |
| PrimaryButtonStyle | Gold filled button | Primary CTAs |
| SecondaryButtonStyle | Outlined button | Secondary actions |

---

## 8. Implementation Roadmap

### Phase 1: Foundation (MVP Core)

**Goal:** Establish core data models and basic collection management

| Milestone | Features | Deliverables |
|-----------|----------|--------------|
| M1.1 | Project setup | Xcode project, SwiftData schema, design system |
| M1.2 | Data models | Fragrance, Note, FragranceNote, FragranceMetrics |
| M1.3 | Collection view | Browse, search, filter, sort fragrances |
| M1.4 | Fragrance detail | Note pyramid, performance display, basic info |
| M1.5 | Add fragrance | Form with all metadata fields |
| M1.6 | Data seeding | Sample fragrances and notes for testing |

### Phase 2: Personalization

**Goal:** Enable user-specific data and tracking

| Milestone | Features | Deliverables |
|-----------|----------|--------------|
| M2.1 | UserFragrance model | Purchase info, personal rating, signature flag |
| M2.2 | WearLog model | Date, occasion, weather, satisfaction tracking |
| M2.3 | Quick log sheet | Modal form for logging wears |
| M2.4 | Wear history view | Filterable log list with statistics |
| M2.5 | Cost per wear | Calculated analytics |

### Phase 3: Intelligence

**Goal:** Implement smart recommendation engine

| Milestone | Features | Deliverables |
|-----------|----------|--------------|
| M3.1 | RecommendationEngine service | Scoring algorithm implementation |
| M3.2 | Context selection | Occasion, time, weather input UI |
| M3.3 | Results view | Top picks with confidence, alternatives |
| M3.4 | Dashboard integration | Today's recommendation card |
| M3.5 | Personalization bonuses | Signature/favorite weighting |

### Phase 4: Layering

**Goal:** Build fragrance combination features

| Milestone | Features | Deliverables |
|-----------|----------|--------------|
| M4.1 | LayeringCombination model | Compatibility, ratio, application order |
| M4.2 | Browse combinations | List view with filters and sorting |
| M4.3 | Combination detail | Full info, visual ratio, application tips |
| M4.4 | Layering calculator | Custom pair testing with score |
| M4.5 | Save combinations | Persist user-created combos |

### Phase 5: Polish

**Goal:** Complete user experience and settings

| Milestone | Features | Deliverables |
|-----------|----------|--------------|
| M5.1 | Dashboard completion | Stats, recent logs, quick actions |
| M5.2 | Profile & settings | User info, preferences, app settings |
| M5.3 | Dark mode | Theme switching support |
| M5.4 | Performance optimization | Query optimization, lazy loading |
| M5.5 | Bug fixes & refinement | Edge cases, UI polish |

---

## 9. Success Metrics

### 9.1 Key Performance Indicators (KPIs)

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Collection Engagement** | 50+ fragrances/user average | Database query |
| **Recommendation Acceptance** | >60% of recommendations accepted | Tracking wasAccepted |
| **Daily Wear Logging** | 70% of users log 1+ wear/day | WearLog count |
| **Layering Exploration** | 30% of users try calculator | Feature usage tracking |
| **Session Duration** | 3+ minutes average | Analytics |
| **Retention** | 40% D7, 20% D30 | Cohort analysis |

### 9.2 User Satisfaction Metrics

| Metric | Target |
|--------|--------|
| App Store Rating | 4.5+ stars |
| Recommendation Satisfaction | 4+ average rating |
| Feature Completeness Score | 90%+ tasks completable |

---

## 10. Future Enhancements

### 10.1 Near-Term (Next Release)

| Feature | Description | Priority |
|---------|-------------|----------|
| WeatherKit Integration | Real weather data for recommendations | P1 |
| Image Support | Upload/display bottle images | P1 |
| Data Export | JSON/CSV backup functionality | P2 |
| Dark Mode Completion | Full theme implementation | P2 |

### 10.2 Medium-Term

| Feature | Description | Priority |
|---------|-------------|----------|
| iCloud Sync | Cross-device data synchronization | P1 |
| Fragrantica API | Auto-populate fragrance details | P2 |
| Watch Companion | Quick logging from Apple Watch | P2 |
| Widgets | Home screen recommendation widget | P2 |

### 10.3 Long-Term Vision

| Feature | Description |
|---------|-------------|
| Social Features | Share combinations, follow collectors |
| Community Ratings | Crowdsourced metrics and reviews |
| AI Note Detection | Photo-based fragrance identification |
| Purchase Tracking | Price history, deal alerts |
| Decant Management | Track and manage fragrance samples |
| Machine Learning | Personalized recommendations using ML |

---

## Appendix A: Sample Data

### Pre-loaded Notes (25)

| Category | Notes |
|----------|-------|
| Fruity | Pineapple, Apple, Blackcurrant |
| Citrus | Bergamot, Lemon, Mandarin, Neroli |
| Woody | Birch, Patchouli, Amberwood, Cedar, Oud |
| Floral | Jasmine, Rose, Iris |
| Animalic | Musk, Ambergris |
| Green | Oakmoss |
| Gourmand | Vanilla, Tonka Bean |
| Spicy | Saffron, Nutmeg |
| Herbal | Lavender |
| Resinous | Fir Resin, Amber |

### Pre-loaded Fragrances (10)

1. **Supremacy Silver** (Afnan) - Aventus clone, 95% accuracy
2. **Vintage Radio** (Generic) - BR540 clone, 90% accuracy
3. **Shaghaf Oud Abyad** (Lattafa) - Oud for Greatness clone, 85% accuracy
4. **Allure Homme Sport Eau Extreme** (Chanel)
5. **L'Homme** (Prada)
6. **Tiger Cal** (Generic) - Clone, 80% accuracy
7. **Halloween Man X** (J. Del Pozo)
8. **Amber Oud Gold** (Al Haramain)
9. **Explorer** (Montblanc)
10. **Pour Homme** (Versace)

### Pre-loaded Combinations (5)

1. The Signature Stack (Supremacy Silver + Vintage Radio)
2. The Statement Maker (Shaghaf Oud Abyad + Tiger Cal)
3. The Daily Driver (Allure Homme Sport + Supremacy Silver)
4. The Gourmand (Vintage Radio + Shaghaf Oud Abyad)
5. The Professional (Prada L'Homme + Supremacy Silver)

---

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| **Concentration** | The percentage of fragrance oils (EDT < EDP < Parfum) |
| **Fragrance Family** | Olfactory classification (woody, floral, oriental, etc.) |
| **Note Pyramid** | Three-tier structure: top (opening), heart (middle), base (dry down) |
| **Sillage** | The trail of scent left behind |
| **Projection** | How far the scent projects from the skin |
| **Longevity** | How long the fragrance lasts |
| **Clone** | A fragrance designed to smell like another |
| **Layering** | Wearing multiple fragrances together |
| **Signature Scent** | A user's go-to, defining fragrance |

---

*Document End*
