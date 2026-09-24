# Customizing Oracle APEX Universal Theme: Low-Code & APEXlang Guide

Transform Oracle APEX applications from the default enterprise aesthetic into a **modern, high-end SaaS product UI**. This guide covers the two distinct customization paths:
1. **The Low-Code (GUI) Way**: Rapid visual theming via Page Designer, Theme Roller, and Static Application Files.
2. **The APEXlang Way**: Spec-driven, version-controlled architecture in `.apx` files for automated CI/CD and AI-driven workflows.

---

## 1. Core Architecture: How Universal Theme (Theme 42) Works

Modern Oracle APEX (21.1+ through 26.1+) builds on three styling layers:
- **CSS Custom Properties (Design Tokens)**: Global variables (`--ut-*` for theme tokens, `--a-*` for APEX internal component mechanics) control colors, surfaces, typography, radii, and shadows.
- **Template Options**: Built-in modifier classes (`t-Region--*`, `t-Button--*`, `t-Form--*`) that alter component layout and appearance declaratively without writing CSS.
- **Theme Styles**: Encapsulated style variants (e.g., *Vita*, *Vita - Dark*, *Redwood Light*, *Iris*) that switch the entire palette and token values dynamically.

> [!TIP]
> **Golden Rule**: Never override styles using brute-force `!important` selectors on raw classes like `.t-Region`. Instead, customize Universal Theme by **overriding CSS custom properties (`--ut-*`)** and leveraging **Template Options**. This keeps your UI resilient across APEX upgrades and responsive to Dark Mode.

---

## 2. The Low-Code Way: Customization via APEX App Builder

The low-code path is ideal for visual prototyping, instant feedback, and declarative development directly in the browser.

```
┌─────────────────────────────────────────────────────────────┐
│                       LOW-CODE WORKFLOW                     │
│                                                             │
│   Theme Roller ──► Template Options ──► Static App Files   │
│   (Colors/Radius)    (Layout/Density)    (CSS Custom Tokens)│
└─────────────────────────────────────────────────────────────┘
```

### 2.1 Theme Roller (WYSIWYG Theming)
1. Run your APEX application and open the **Developer Toolbar** at the bottom of the screen.
2. Click **Customize** > **Theme Roller**.
3. **Customize Core Palette & Global Variables**:
   - **Base Font**: Set base font size (e.g., `15px`) and line-height.
   - **Border Radius**: Increase from `2px/4px` to `8px` or `12px` for a modern, rounded SaaS appearance.
   - **Palette Colors**: Set your Brand Primary (e.g., `#6366F1` Indigo), Accent, Header Background, and Body Background.
4. **Save As Custom Theme Style**:
   - Click **Save As**, name it (e.g., `Modern SaaS Light`), and set it as the **Current Style**.

### 2.2 Template Options (Declarative Layout & Polish)
Inside **Page Designer**, select components to tune their Template Options in the Property Editor:

| Component | Setting / Template Option | Visual Result |
| :--- | :--- | :--- |
| **Regions** | `Template: Blank with Attributes` | Borderless, clean card container ideal for dashboards. |
| **Regions** | `Remove Body Padding` (`t-Region--noPadding`) | Removes gutter padding for edge-to-edge tables or charts. |
| **Regions** | `Accent 1-15` (`t-Region--accentX`) | Adds a modern top-border accent or header highlight. |
| **Buttons** | `Hot` (`t-Button--hot`) + `Pill` / `Large` | High-contrast call-to-action with pill-rounded edges. |
| **Buttons** | `Simple` / `Quiet` | Ghost button for secondary actions (reduces visual clutter). |
| **Form Items** | `Template: Optional - Floating` | Material/SaaS floating labels that animate on focus. |
| **Form Items** | `Stretch Form Item` (`t-Form--stretchInputs`) | Inputs expand to fill grid cells symmetrically. |

### 2.3 Injecting Custom Web Fonts & Modern CSS Tokens
To upgrade typography and surface aesthetics:

1. **Upload Centralized CSS**:
   - Go to **Shared Components** > **Static Application Files**.
   - Create and upload `modern-theme.css` containing CSS variable overrides (see [Section 4](#4-the-modern-saas-design-recipe-copy-paste-css)).
2. **Reference in Application UI**:
   - Go to **Shared Components** > **User Interface Attributes** > **Cascading Style Sheets**.
   - Under **File URLs**, add:
     ```text
     https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap
     #APP_FILES#css/modern-theme.css
     ```

---

## 3. The APEXlang Way: Spec-Driven Code Customization

In Spec-Driven Development (SDD) with APEXlang, theme configurations, CSS attachments, and template options are defined as human-readable, version-controlled `.apx` source files.

```
applications/<app>/
├── application.apx
├── shared-components/
│   ├── static-files.apx
│   └── themes/
│       └── universal-theme/
│           └── theme.apx
└── pages/
    ├── p00000-global-page.apx
    └── p00001-home.apx
```

### 3.1 Theme Definition (`shared-components/themes/universal-theme/theme.apx`)
Configure Universal Theme, attach custom stylesheets, set component defaults, and define custom Theme Styles:

```apexlang
theme universal-theme (
    name: Universal Theme
    themeNumber: 42
    baseTheme: ut-26.1
    style {
        currentThemeStyle: @modern-saas
    }
    javaScript {
        fileUrls: [
            #APEX_FILES#libraries/apex/#MIN_DIRECTORY#widget.stickyWidget#MIN#.js?v=#APEX_VERSION#
            #THEME_FILES#js/theme42#MIN#.js?v=#APEX_VERSION#
        ]
    }
    css {
        fileUrls: [
            #THEME_FILES#css/Core#MIN#.css?v=#APEX_VERSION#
            https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap
            #APP_FILES#css/modern-tokens.css
        ]
    }
    componentDefaults {
        page: @/standard
        navigationBarList: @/navigation-bar
        navigationMenuListPosition: side
        navigationMenuListSide: @/side-navigation-menu
        loginPage: @/login
        errorPage: @/login
        button: @/text
        defaultLabel: @/optional-floating
        optionalLabel: @/optional-floating
        requiredLabel: @/required-floating
        region: @/standard
    }
    regionDefaults {
        breadcrumbs: @/title-bar
        interactiveReports: @/interactive-report
    }

    style modern-saas (
        name: "Modern SaaS"
        css {
            fileUrls: [
                #APP_FILES#css/modern-tokens.css
            ]
            cssClasses: t-ModernSaaS
        }
        themeRollerAttributes {
            readOnly: false
            outputCssFileUrl: #THEME_FILES#css/theme-modern-saas.css
            jsonConfig: ```{
                "vars": {
                    "@g_Accent-BG": "#6366F1",
                    "@g_Primary-BG": "#0F172A"
                }
            }```
        }
        advanced {
            staticId: modern-saas
            endUserCanPick: true
            accessibilityTested: true
        }
    )
)
```

### 3.2 Declaring Static Files (`shared-components/static-files.apx`)
Register the external modern theme stylesheet in static files:

```apexlang
file "css/modern-tokens.css" (
    mimeType: text/css
    charSet: utf-8
)
```

### 3.3 Application Navigation & UI Settings (`application.apx`)
Set modern navigation list templates and collapsible menu behaviors:

```apexlang
app MY-APP (
    name: "Modern Dashboard"
    navigationMenu {
        listTemplate: @/side-navigation-menu
        templateOptions: [
            #DEFAULT#
            js-defaultCollapsed
            js-navCollapsed--hidden
            t-TreeNav--styleA
        ]
        list: @navigation-menu
    }
    userInterface {
        currentTheme: @universal-theme
        globalPage: 0
        addBuiltWithApexToFooter: false
    }
)
```

### 3.4 Page & Region Styling (`pages/p00001-home.apx`)
Apply template options, utility classes, and custom container classes directly in page declarations:

```apexlang
page 1 (
    name: "Dashboard"
    alias: DASHBOARD
    title: "Executive Dashboard"
    appearance {
        pageTemplate: @/standard
        templateOptions: #DEFAULT#
    }

    region summary-cards (
        name: "KPI Metrics"
        type: staticContent
        layout {
            sequence: 10
            slot: body
        }
        appearance {
            template: @/blank-with-attributes
            templateOptions: [
                #DEFAULT#
                t-Region--noPadding
            ]
            cssClasses: [
                "saas-card"
                "glass-effect"
            ]
        }
    )
)
```

---

## 4. The "Modern SaaS" Design Recipe (Copy-Paste CSS)

Save this stylesheet as `modern-tokens.css`. It overrides APEX Universal Theme CSS variables to instantly replace dated gradients and boxy borders with a **clean, modern fintech/SaaS aesthetic**:

```css
/**
 * Modern SaaS Universal Theme Overrides
 * Compatible with APEX 22.x - 26.x Universal Theme (Theme 42)
 */

:root {
  /* 1. Modern Typography */
  --a-base-font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --a-base-font-size: 0.9375rem; /* 15px */
  --a-base-line-height: 1.5;

  /* 2. Modern Color Palette */
  --ut-palette-primary: #4f46e5;          /* Indigo 600 */
  --ut-palette-primary-contrast: #ffffff;
  --ut-palette-primary-dark: #4338ca;
  --ut-palette-primary-light: #e0e7ff;
  --ut-palette-accent: #0ea5e9;           /* Sky 500 */
  --ut-palette-success: #10b981;          /* Emerald 500 */
  --ut-palette-warning: #f59e0b;          /* Amber 500 */
  --ut-palette-danger: #ef4444;           /* Rose 500 */

  /* 3. Surface & Backgrounds */
  --ut-body-bg-color: #f8fafc;            /* Slate 50 */
  --ut-component-background-color: #ffffff;
  --ut-component-border-color: #e2e8f0;   /* Slate 200 */
  --ut-component-border-radius: 12px;     /* Curvature for modern feel */

  /* 4. Elevation & Shadows */
  --ut-component-shadow: 0 1px 3px 0 rgb(0 0 0 / 0.05), 0 1px 2px -1px rgb(0 0 0 / 0.05);
  --ut-component-shadow-hover: 0 10px 15px -3px rgb(0 0 0 / 0.08), 0 4px 6px -4px rgb(0 0 0 / 0.04);

  /* 5. Header & Navigation */
  --ut-header-background-color: #ffffff;
  --ut-header-text-color: #0f172a;
  --ut-header-border-color: #f1f5f9;
  --ut-nav-background-color: #ffffff;
  --ut-nav-text-color: #475569;
  --ut-nav-active-background-color: #eef2ff;
  --ut-nav-active-text-color: #4f46e5;
}

/* Polished Region Cards */
.t-Region {
  border-radius: var(--ut-component-border-radius) !important;
  border: 1px solid var(--ut-component-border-color) !important;
  box-shadow: var(--ut-component-shadow) !important;
  transition: box-shadow 0.2s ease, transform 0.2s ease;
}

.t-Region:hover {
  box-shadow: var(--ut-component-shadow-hover) !important;
}

/* Clean Header Bar */
.t-Header-branding {
  border-bottom: 1px solid var(--ut-header-border-color);
}

/* Glassmorphism Utility (optional class for modal dialogs & hero cards) */
.glass-effect {
  background: rgba(255, 255, 255, 0.8) !important;
  backdrop-filter: blur(12px) !important;
  -webkit-backdrop-filter: blur(12px) !important;
  border: 1px solid rgba(255, 255, 255, 0.4) !important;
}

/* Refined Form Controls & Focus Ring */
.apex-item-text,
.apex-item-select,
.apex-item-textarea {
  border-radius: 8px !important;
  border: 1px solid #cbd5e1 !important;
  padding: 0.625rem 0.875rem !important;
  transition: border-color 0.15s ease, box-shadow 0.15s ease !important;
}

.apex-item-text:focus,
.apex-item-select:focus,
.apex-item-textarea:focus {
  border-color: var(--ut-palette-primary) !important;
  box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.15) !important;
  outline: none !important;
}

/* Modern Pill & Primary Buttons */
.t-Button--hot {
  background: linear-gradient(135deg, var(--ut-palette-primary) 0%, var(--ut-palette-primary-dark) 100%) !important;
  border: none !important;
  border-radius: 8px !important;
  box-shadow: 0 2px 4px rgba(79, 70, 229, 0.25) !important;
  font-weight: 600 !important;
  transition: opacity 0.2s ease, transform 0.1s ease !important;
}

.t-Button--hot:hover {
  opacity: 0.92;
  transform: translateY(-1px);
}
```

---

## 5. Low-Code vs. APEXlang: When to Use Which

| Dimension | Low-Code Way (Page Designer / Theme Roller) | APEXlang Way (`.apx` Files) |
| :--- | :--- | :--- |
| **Primary Audience** | Citizen developers, UI designers, visual prototyping | Full-stack developers, AI agents, DevOps engineers |
| **Feedback Loop** | Instant WYSIWYG in the browser | Code edit -> CLI validation (`apexctl.mjs`) -> Git commit |
| **Version Control** | Poor (stored in DB metadata tables; exported as SQL) | Native Git branch/diff/merge per component file |
| **AI Generation** | High friction (requires clicking or recording macros) | Frictionless (LLMs author structured DSL directly) |
| **Upgrade Safety** | High (Theme Roller tracks UT updates) | High (declarative schema validation verifies contracts) |
| **Recommendation** | **Prototype** your palette & tokens visually in Theme Roller | **Export & lock** your design tokens into `.apx` for CI/CD |

---

## 6. Action Plan to Overhaul Your Application's UI

1. **Step 1 (Typography & Palette)**: Choose a modern Google Font (e.g., *Plus Jakarta Sans* or *Inter*) and define a cohesive 4-color palette (Primary, Accent, Background, Border).
2. **Step 2 (Token File)**: Place the provided CSS snippet in `modern-tokens.css` inside `shared-components/static-files.apx` (or upload to Static Application Files).
3. **Step 3 (Theme Reference)**: Attach the stylesheet in `theme.apx` under `css { fileUrls: [...] }` or via Shared Components > User Interface Attributes.
4. **Step 4 (Template Options)**: Ensure all form items use floating labels (`@/optional-floating`), content cards use `t-Region--noPadding` or `@/blank-with-attributes`, and buttons use the `t-Button--hot` style.
5. **Step 5 (Automate)**: Validate and lock the layout using `node tools/apexctl.mjs runtime validate` before deploying to staging/production.
