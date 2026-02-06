# FuckCorpo - Design System
## "Capitalist Satire" Aesthetic

---

## Design Philosophy

**Concept**: Subversive corporate aesthetic that looks professional but acts rebellious. We're appropriating the visual language of Wall Street and corporate America to expose the absurdity of workplace exploitation.

**Tone**: Satirical, sophisticated, ironic professionalism. Think *The Onion* meets *Wall Street Journal*.

**Visual Strategy**: Use the polished, "premium" aesthetic of financial institutions and corporate reports, but subvert it with content that celebrates worker autonomy and bathroom breaks.

---

## Color Palette

### Primary Colors

**Corporate Navy**
- Hex: `#0a1128`
- RGB: `10, 17, 40`
- Usage: Primary backgrounds, headers, main UI elements
- Represents: Corporate authority, "serious business"

**Crisp White**
- Hex: `#ffffff`
- RGB: `255, 255, 255`
- Usage: Primary text on dark backgrounds, card backgrounds, clean spaces
- Represents: Clarity, professionalism, corporate polish

### Accent Colors

**Stock Market Green** (Gains)
- Hex: `#00b559`
- RGB: `0, 181, 89`
- Usage: Positive earnings, success states, "in the green"
- Represents: Money earned, winning

**Stock Market Red** (Losses/Time)
- Hex: `#e63946`
- RGB: `230, 57, 70`
- Usage: Time indicators, warnings, "spent time"
- Represents: Company's loss is your gain

**Achievement Gold**
- Hex: `#ffd60a`
- RGB: `255, 214, 10`
- Usage: Badges, achievements, milestone highlights
- Represents: Premium status, excellence

### Supporting Colors

**Cool Gray** (Shadows & Depth)
- Hex: `#778da9`
- RGB: `119, 141, 169`
- Usage: Borders, dividers, secondary text, subtle backgrounds
- Represents: Corporate monotony

**Slate** (Secondary Backgrounds)
- Hex: `#1e2749`
- RGB: `30, 39, 73`
- Usage: Card backgrounds, sections, elevated surfaces
- Represents: Depth, layering

**Muted Gold** (Subtle Accents)
- Hex: `#c9a648`
- RGB: `201, 166, 72`
- Usage: Hover states, subtle highlights, premium touches
- Represents: Understated wealth

---

## Typography

### Display Font: Playfair Display

**Purpose**: Headlines, hero text, major callouts
**Weight**: 700 (Bold) and 900 (Black)
**Character**: Editorial, sophisticated, authoritative
**Usage**:
- Main landing page headline
- Section headers
- Major statistics displays
- "Report" titles

```css
font-family: 'Playfair Display', serif;
font-weight: 700;
font-size: 48px - 72px;
line-height: 1.2;
letter-spacing: -0.02em;
```

### Body Font: Work Sans

**Purpose**: Body text, UI elements, general content
**Weights**: 400 (Regular), 500 (Medium), 600 (Semi-Bold)
**Character**: Clean, corporate, highly readable
**Usage**:
- Paragraph text
- Navigation items
- Button labels
- Form inputs
- Descriptions

```css
font-family: 'Work Sans', sans-serif;
font-weight: 400;
font-size: 16px - 18px;
line-height: 1.6;
letter-spacing: 0.01em;
```

### Data Font: Roboto Mono

**Purpose**: Numbers, data displays, financial information
**Weights**: 400 (Regular), 700 (Bold)
**Character**: Monospaced, technical, financial terminal
**Usage**:
- All dollar amounts
- Statistics
- Timer displays
- Leaderboard numbers
- Data tables

```css
font-family: 'Roboto Mono', monospace;
font-weight: 700;
font-size: 24px - 48px (for large earnings)
font-size: 14px - 16px (for tables/small data)
line-height: 1.4;
letter-spacing: 0.05em;
```

### Type Scale

- **H1**: 64px / 4rem (Playfair Display Black)
- **H2**: 48px / 3rem (Playfair Display Bold)
- **H3**: 36px / 2.25rem (Playfair Display Bold)
- **H4**: 24px / 1.5rem (Work Sans Semi-Bold)
- **Body Large**: 18px / 1.125rem (Work Sans Regular)
- **Body**: 16px / 1rem (Work Sans Regular)
- **Body Small**: 14px / 0.875rem (Work Sans Regular)
- **Caption**: 12px / 0.75rem (Work Sans Medium)

---

## Design Elements & Patterns

### Stock Ticker Tape

**Visual**: Continuous scrolling bar with running totals and stats
**Placement**: Top of dashboard, beneath header
**Animation**: Smooth left-to-right or right-to-left scroll
**Content**: "TOTAL EARNED: $X,XXX.XX | TIME TODAY: XX:XX | RANK: #XXX | LIFETIME: $XX,XXX"
**Styling**:
- Background: Stock Market Green with 10% opacity
- Text: Corporate Navy
- Border: 1px solid Stock Market Green

### Graph Paper Background

**Visual**: Subtle grid pattern reminiscent of accounting ledgers
**Usage**: Section backgrounds, cards
**Implementation**: 
```css
background-image: 
  linear-gradient(rgba(119, 141, 169, 0.1) 1px, transparent 1px),
  linear-gradient(90deg, rgba(119, 141, 169, 0.1) 1px, transparent 1px);
background-size: 20px 20px;
```

### Professional Charts

**Style**: Clean, corporate data visualizations
**Types**:
- Line charts for earnings over time
- Bar charts for daily/weekly comparisons
- Pie charts for break category distribution
- Candlestick charts (satirical) for bathroom session patterns

**Colors**:
- Axis lines: Cool Gray
- Grid lines: Cool Gray at 20% opacity
- Data: Stock Market Green (positive), Stock Market Red (time)

### Faux Business Card Layouts

**Usage**: User profiles, shareable stats cards
**Elements**:
- Embossed effect on text
- Subtle grain texture
- Gold foil effect on achievement badges
- Professional headshot placeholder (or avatar)
- "Title": Most productive bathroom user, etc.

### Glossy "Premium" Materials

**Card Styling**:
```css
background: linear-gradient(135deg, #1e2749 0%, #0a1128 100%);
border: 1px solid rgba(119, 141, 169, 0.3);
box-shadow: 
  0 4px 6px rgba(0, 0, 0, 0.1),
  0 1px 3px rgba(0, 0, 0, 0.08),
  inset 0 1px 0 rgba(255, 255, 255, 0.05);
border-radius: 8px;
```

### Achievement Badges

**Design**: Corporate medal/seal style
**Elements**:
- Circular or shield shape
- Gold or silver metallic gradient
- Embossed text
- Ribbon element
- Drop shadow for depth

### Report Headers

**Style**: Official document aesthetic
**Elements**:
- "QUARTERLY EARNINGS REPORT" style headers
- Faux company letterhead
- Date/time stamps
- "CONFIDENTIAL" watermarks (satirical)
- Official-looking stamps and seals

---

## UI Components

### Buttons

**Primary Button**
```css
background: linear-gradient(180deg, #00b559 0%, #008f47 100%);
color: #ffffff;
font-family: 'Work Sans', sans-serif;
font-weight: 600;
padding: 14px 28px;
border-radius: 6px;
border: none;
box-shadow: 0 2px 8px rgba(0, 181, 89, 0.3);
transition: all 0.2s ease;
```

**Hover State**:
```css
transform: translateY(-2px);
box-shadow: 0 4px 12px rgba(0, 181, 89, 0.4);
```

**Secondary Button**
```css
background: transparent;
color: #00b559;
border: 2px solid #00b559;
font-family: 'Work Sans', sans-serif;
font-weight: 600;
padding: 12px 26px;
border-radius: 6px;
```

### Input Fields

```css
background: rgba(255, 255, 255, 0.05);
border: 1px solid rgba(119, 141, 169, 0.3);
border-radius: 4px;
padding: 12px 16px;
color: #ffffff;
font-family: 'Work Sans', sans-serif;
font-size: 16px;
```

**Focus State**:
```css
border-color: #00b559;
box-shadow: 0 0 0 3px rgba(0, 181, 89, 0.1);
```

### Cards

**Standard Card**
```css
background: #1e2749;
border: 1px solid rgba(119, 141, 169, 0.2);
border-radius: 8px;
padding: 24px;
box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
```

**Elevated Card** (hover/important)
```css
background: linear-gradient(135deg, #1e2749 0%, #0a1128 100%);
border: 1px solid rgba(255, 214, 10, 0.3);
box-shadow: 
  0 8px 16px rgba(0, 0, 0, 0.2),
  inset 0 1px 0 rgba(255, 255, 255, 0.05);
```

### Data Display (Large Numbers)

**Earnings Display**
```css
font-family: 'Roboto Mono', monospace;
font-weight: 700;
font-size: 56px;
color: #00b559;
text-shadow: 0 0 20px rgba(0, 181, 89, 0.3);
letter-spacing: 0.05em;
```

**Timer Display**
```css
font-family: 'Roboto Mono', monospace;
font-weight: 400;
font-size: 48px;
color: #ffffff;
letter-spacing: 0.1em;
```

### Navigation

**Top Navigation Bar**
```css
background: rgba(10, 17, 40, 0.95);
backdrop-filter: blur(10px);
border-bottom: 1px solid rgba(119, 141, 169, 0.2);
padding: 16px 24px;
```

### Tooltips

```css
background: #0a1128;
color: #ffffff;
font-family: 'Work Sans', sans-serif;
font-size: 14px;
padding: 8px 12px;
border-radius: 4px;
border: 1px solid rgba(255, 214, 10, 0.3);
box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
```

---

## Animation & Interactions

### Micro-interactions

**Number Count-Up**
- Earnings animate from 0 to final value on page load
- Duration: 1.5s with easeOutExpo
- Add satisfying "cha-ching" feel

**Hover Elevations**
```css
transition: transform 0.2s ease, box-shadow 0.2s ease;
```
```css
:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
}
```

**Button Press**
```css
:active {
  transform: translateY(0);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}
```

### Page Transitions

**Fade + Slide**
```css
@keyframes fadeSlideIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

### Loading States

**Skeleton Screens**
- Use Cool Gray with shimmer effect
- Maintain layout structure
- Smooth transition to real content

**Progress Indicators**
- Stock Market Green fills
- Percentage displayed in Roboto Mono
- Smooth, linear progress

---

## Layout & Spacing

### Spacing Scale (8pt Grid)

- **XXS**: 4px (0.25rem)
- **XS**: 8px (0.5rem)
- **S**: 16px (1rem)
- **M**: 24px (1.5rem)
- **L**: 32px (2rem)
- **XL**: 48px (3rem)
- **XXL**: 64px (4rem)
- **XXXL**: 96px (6rem)

### Container Widths

- **Maximum Content Width**: 1400px
- **Standard Content Width**: 1200px
- **Narrow Content Width**: 800px (for reading)
- **Card Max Width**: 600px

### Breakpoints

```css
/* Mobile First */
--mobile: 320px
--tablet: 768px
--desktop: 1024px
--wide: 1440px
```

---

## Visual Effects

### Gradients

**Premium Gradient** (backgrounds)
```css
background: linear-gradient(135deg, #1e2749 0%, #0a1128 100%);
```

**Gold Accent Gradient** (achievements)
```css
background: linear-gradient(135deg, #ffd60a 0%, #c9a648 100%);
```

**Glow Effect** (earnings, CTAs)
```css
box-shadow: 0 0 20px rgba(0, 181, 89, 0.4);
```

### Textures

**Paper Grain** (subtle on cards)
```css
background-image: url('data:image/svg+xml,...'); /* grain texture */
opacity: 0.03;
```

**Noise Overlay** (premium feel)
```css
background-image: url('noise.png');
opacity: 0.02;
mix-blend-mode: overlay;
```

---

## Iconography

### Style Guidelines

- **Line weight**: 2px strokes
- **Style**: Outlined, professional, minimal
- **Size**: 24px x 24px standard
- **Color**: Inherit from parent or Cool Gray

### Key Icons Needed

- Dollar sign (earnings)
- Clock/Timer
- Trophy (achievements)
- Bar chart (statistics)
- User profile
- Settings gear
- Calendar
- Briefcase
- Graph trending up/down
- Crown (leaderboard)

---

## Accessibility

### Contrast Ratios

All text meets WCAG AAA standards:
- **Large text** (18px+): Minimum 4.5:1
- **Small text**: Minimum 7:1
- **UI elements**: Minimum 3:1

### Focus States

```css
:focus-visible {
  outline: 2px solid #00b559;
  outline-offset: 2px;
  border-radius: 4px;
}
```

### Motion

- Respect `prefers-reduced-motion`
- Provide option to disable animations
- Essential animations only for core UX

---

## Brand Voice in Design

### Copy Tone

**Examples**:
- "YOUR QUARTERLY EARNINGS REPORT" (header)
- "Maximize Your Assets (While Sitting)" (tagline)
- "INVESTMENT STRATEGY: Bowel Movements" (satirical section)
- "SHAREHOLDER VALUE: YOU" (emphasis)
- "Market Analysis: Bathroom Trends" (reports)

### Satirical Elements to Include

- Fake stock ticker symbols (e.g., "$POOP", "$TIME")
- "Annual Report" style summaries
- "Board of Directors: You" sections
- CEO comparison stats
- "Quarterly earnings call" language
- "Investor relations" humor

---

## Social Media Assets

### Shareable Cards Specs

**Dimensions**: 1200px x 630px (optimal for all platforms)
**Design**:
- Corporate letterhead style
- Large earnings number (Roboto Mono)
- "EARNINGS STATEMENT" header (Playfair Display)
- Graph paper background
- Gold seal/badge
- Watermark logo

**Color Scheme**: Same as main app
**Export**: PNG with transparent elements option

---

## Dark Mode (Primary) / Light Mode (Optional)

### Current: Dark Mode

Primary experience as documented above.

### Optional Light Mode

**If implemented:**
- **Background**: Crisp White (#ffffff)
- **Text**: Corporate Navy (#0a1128)
- **Accents**: Same (Stock Green, Red, Gold)
- **Cards**: Very light gray (#f8f9fa)
- **Borders**: Cool Gray at 30% opacity

---

## Implementation Notes

### CSS Variables Setup

```css
:root {
  /* Colors */
  --color-navy: #0a1128;
  --color-slate: #1e2749;
  --color-white: #ffffff;
  --color-green: #00b559;
  --color-red: #e63946;
  --color-gold: #ffd60a;
  --color-gray: #778da9;
  --color-muted-gold: #c9a648;
  
  /* Typography */
  --font-display: 'Playfair Display', serif;
  --font-body: 'Work Sans', sans-serif;
  --font-mono: 'Roboto Mono', monospace;
  
  /* Spacing */
  --space-xs: 0.5rem;
  --space-s: 1rem;
  --space-m: 1.5rem;
  --space-l: 2rem;
  --space-xl: 3rem;
  
  /* Shadows */
  --shadow-sm: 0 2px 4px rgba(0, 0, 0, 0.1);
  --shadow-md: 0 4px 8px rgba(0, 0, 0, 0.15);
  --shadow-lg: 0 8px 16px rgba(0, 0, 0, 0.2);
  
  /* Border Radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
}
```

### Font Loading

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Work+Sans:wght@400;500;600&family=Roboto+Mono:wght@400;700&display=swap" rel="stylesheet">
```

---

## Next Steps

1. Create design system component library
2. Build style guide page showing all components
3. Develop reusable React/Vue components
4. Create social media template generator
5. Design marketing landing page
6. Prototype dashboard layout

---

**Last Updated**: January 2026
**Version**: 1.0
**Design Lead**: [Your Name]
