# TrustMarket Design System

> Profesyonel, canlı, enerjik — Web ve Mobil tam uyumlu tasarım dili

## Brand Identity

**Ürün Hissi:**
- Tech startup modernliği + güvenli pazar ciddiyeti
- Enerjik: canlı vurgu renkleri + yumuşak gradient'ler
- Premium: temiz tipografi, doğru boşluk, perfect kontrast

**Tasarım Prensipleri:**
- Ferahlık: bol beyaz alan, rahat nefes alır
- Canlılık: dikkat çekici ama göz yormayan
- Tutarlılık: web ve mobil aynı dil
- Erişilebilirlik: WCAG AA minimum

---

## Color Tokens

### Light Mode (Default)

#### Neutrals
```
background:    hsl(220, 35%, 97%)   #F5F7FA  - Ana zemin (açık gri-mavi)
surface:       hsl(0, 0%, 100%)     #FFFFFF  - Kartlar, paneller (beyaz)
surface-2:     hsl(220, 30%, 98%)   #F8F9FB  - İkinci seviye yüzeyler
border:        hsl(220, 15%, 88%)   #DCE1E7  - Kenarlıklar
text:          hsl(220, 25%, 12%)   #1A1F2E  - Ana metin
text-muted:    hsl(220, 15%, 50%)   #6B7280  - İkincil metin
```

#### Brand Colors
```
primary:       hsl(238, 75%, 58%)   #5B50E8  - Ana marka rengi (mavi-mor)
primary-hover: hsl(238, 75%, 52%)   #4939D9  - Hover state
primary-light: hsl(238, 75%, 95%)   #EEEDFC  - Hafif arkaplan

accent:        hsl(28, 95%, 55%)    #FA8F21  - Vurgu (turuncu)
accent-hover:  hsl(28, 95%, 48%)    #E57D0F  - Hover state
accent-light:  hsl(28, 95%, 95%)    #FFF4E6  - Hafif arkaplan
```

#### Semantic Colors
```
success:       hsl(145, 65%, 45%)   #2AB578  - Başarı (yeşil)
success-bg:    hsl(145, 65%, 96%)   #EEFBF4  - Başarı arkaplan

warning:       hsl(38, 92%, 52%)    #F59E0B  - Uyarı (amber)
warning-bg:    hsl(38, 92%, 95%)    #FFF7E6  - Uyarı arkaplan

danger:        hsl(358, 75%, 58%)   #EF4444  - Hata (kırmızı)
danger-bg:     hsl(358, 75%, 96%)   #FEF2F2  - Hata arkaplan

info:          hsl(210, 75%, 55%)   #3B82F6  - Bilgi (mavi)
info-bg:       hsl(210, 75%, 96%)   #EFF6FF  - Bilgi arkaplan
```

### Dark Mode

#### Neutrals
```
background:    hsl(220, 25%, 10%)   #13161F  - Ana zemin (koyu gri-mavi)
surface:       hsl(220, 20%, 14%)   #1D2231  - Kartlar, paneller
surface-2:     hsl(220, 18%, 18%)   #252A3A  - İkinci seviye yüzeyler
border:        hsl(220, 15%, 25%)   #343A4A  - Kenarlıklar
text:          hsl(220, 20%, 92%)   #E5E7EB  - Ana metin
text-muted:    hsl(220, 15%, 65%)   #9CA3AF  - İkincil metin
```

#### Brand Colors
```
primary:       hsl(238, 75%, 65%)   #7B70F5  - Ana marka (daha açık)
primary-hover: hsl(238, 75%, 70%)   #9289F7  - Hover state
primary-light: hsl(238, 75%, 18%)   #1E1B42  - Hafif arkaplan

accent:        hsl(28, 95%, 60%)    #FCA340  - Vurgu (daha açık turuncu)
accent-hover:  hsl(28, 95%, 65%)    #FDB960  - Hover state
accent-light:  hsl(28, 95%, 15%)    #3D2410  - Hafif arkaplan
```

#### Semantic Colors
```
success:       hsl(145, 65%, 55%)   #34D399  - Başarı (daha açık)
success-bg:    hsl(145, 65%, 15%)   #0C3A24

warning:       hsl(38, 92%, 58%)    #FBBF24  - Uyarı (daha açık)
warning-bg:    hsl(38, 92%, 15%)    #3D2F0F

danger:        hsl(358, 75%, 62%)   #F87171  - Hata (daha açık)
danger-bg:     hsl(358, 75%, 15%)   #3D1515

info:          hsl(210, 75%, 62%)   #60A5FA  - Bilgi (daha açık)
info-bg:       hsl(210, 75%, 15%)   #0F2942
```

---

## Typography

### Font Families

**Display (Headings):**
- Primary: `Inter` (Google Fonts)
- Weights: 500 (Medium), 600 (Semibold), 700 (Bold)
- Usage: H1-H6, büyük başlıklar, vurgu metinler

**Body (Content):**
- Primary: `Inter` (Google Fonts)
- Weights: 400 (Regular), 500 (Medium)
- Usage: Paragraflar, liste, form input'lar

**Fallback:**
- `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`

### Type Scale

```
display-lg:  36px / 44px  - Bold 700     - Hero başlıklar
display-md:  30px / 38px  - Bold 700     - Sayfa başlıklar
display-sm:  24px / 32px  - Semibold 600 - Section başlıklar

title-lg:    20px / 28px  - Semibold 600 - Kart başlıkları
title-md:    18px / 26px  - Semibold 600 - Alt başlıklar
title-sm:    16px / 24px  - Medium 500   - Liste başlıkları

body-lg:     16px / 24px  - Regular 400  - Ana içerik
body-md:     14px / 20px  - Regular 400  - Standart metin
body-sm:     12px / 18px  - Regular 400  - Yardımcı metin

label-lg:    14px / 20px  - Medium 500   - Buton metinleri
label-md:    12px / 18px  - Medium 500   - Form label'ları
label-sm:    10px / 16px  - Medium 500   - Badge'ler, tag'ler
```

---

## Spacing

**8pt Grid Sistemi:**

```
xs:   4px   - 0.5 rem  - Çok küçük boşluk (icon padding)
sm:   8px   - 1 rem    - Küçük boşluk (chip padding)
md:   12px  - 1.5 rem  - Orta boşluk (input padding)
lg:   16px  - 2 rem    - Büyük boşluk (card padding)
xl:   24px  - 3 rem    - Çok büyük boşluk (section margin)
2xl:  32px  - 4 rem    - Ekstra büyük (sayfa padding)
3xl:  48px  - 6 rem    - Massive (section spacing)
4xl:  64px  - 8 rem    - Hero spacing
```

**Component-specific:**
```
button-padding-x:  16px (md input), 24px (lg CTA)
button-padding-y:  10px (md), 14px (lg)
card-padding:      20px
modal-padding:     24px
page-padding-x:    16px (mobile), 24px (tablet+)
page-padding-y:    24px
```

---

## Border Radius

```
sm:   6px   - Küçük elementler (badge, tag)
md:   8px   - Orta elementler (button, input, chip)
lg:   12px  - Büyük elementler (card, modal)
xl:   16px  - Çok büyük (hero card, image)
2xl:  24px  - Massive (section container)
full: 9999px - Tam yuvarlak (avatar, pill)
```

**Component-specific:**
```
button:       8px (md)
input:        8px (md)
card:         12px (lg)
modal:        16px (xl)
badge:        9999px (full)
avatar:       9999px (full)
image:        12px (lg)
```

---

## Shadows

### Light Mode
```
soft:     0 1px 3px rgba(0, 0, 0, 0.06)
         0 1px 2px rgba(0, 0, 0, 0.04)
         - Küçük elevation (chip, badge)

medium:   0 4px 8px rgba(0, 0, 0, 0.08)
         0 2px 4px rgba(0, 0, 0, 0.04)
         - Orta elevation (card, button hover)

large:    0 12px 24px rgba(0, 0, 0, 0.10)
         0 4px 8px rgba(0, 0, 0, 0.06)
         - Büyük elevation (modal, dropdown)

xl:       0 20px 40px rgba(0, 0, 0, 0.12)
         0 8px 16px rgba(0, 0, 0, 0.08)
         - Çok büyük elevation (sheet, hero)
```

### Dark Mode
```
soft:     0 1px 3px rgba(0, 0, 0, 0.20)
         0 1px 2px rgba(0, 0, 0, 0.15)

medium:   0 4px 8px rgba(0, 0, 0, 0.30)
         0 2px 4px rgba(0, 0, 0, 0.20)

large:    0 12px 24px rgba(0, 0, 0, 0.40)
         0 4px 8px rgba(0, 0, 0, 0.25)

xl:       0 20px 40px rgba(0, 0, 0, 0.50)
         0 8px 16px rgba(0, 0, 0, 0.35)
```

---

## Component Specifications

### Buttons

**Primary (CTA):**
- Background: `primary`
- Text: white
- Height: 44px (md), 52px (lg)
- Padding: 16px 24px (md), 20px 32px (lg)
- Radius: 8px
- Shadow: soft (rest), medium (hover)
- Font: label-lg (14px Medium)
- State:
  - Hover: `primary-hover` + medium shadow
  - Active: scale(0.98)
  - Disabled: opacity 0.5

**Secondary:**
- Background: transparent
- Border: 1.5px solid `border`
- Text: `text`
- Height/Padding: same as primary
- State:
  - Hover: background `surface-2`
  - Active: background `surface-2` + border `primary`

**Accent (Warm CTA):**
- Background: `accent`
- Text: white
- Same dimensions as Primary
- Use sparingly for special actions

**Ghost:**
- Background: transparent
- Text: `primary`
- Hover: background `primary-light`

### Inputs

**Text Input:**
- Height: 44px
- Padding: 12px 16px
- Radius: 8px
- Border: 1.5px solid `border`
- Background: `surface`
- Font: body-md
- Placeholder: `text-muted`
- Focus:
  - Border: `primary`
  - Shadow: 0 0 0 3px `primary-light`

**Select / Dropdown:**
- Same as Text Input
- Add chevron icon (right aligned)

**Textarea:**
- Min-height: 100px
- Padding: 12px 16px
- Resize: vertical only

### Cards

**Default Card:**
- Background: `surface`
- Radius: 12px
- Padding: 20px
- Shadow: soft
- Border: 1px solid `border` (optional)
- Hover: shadow medium + translate(-2px)

**Listing Card:**
- Background: `surface`
- Radius: 12px
- Padding: 0 (image full width)
- Shadow: soft
- Content padding: 16px
- Hover: shadow medium + scale(1.01)

**Interactive Card:**
- Same as Default
- Cursor: pointer
- Transition: all 200ms ease

### Badges

**Status Badge:**
- Height: 24px
- Padding: 6px 12px
- Radius: 9999px (full)
- Font: label-sm (10px Medium)
- Variants:
  - Success: `success` bg + white text
  - Warning: `warning` bg + white text
  - Danger: `danger` bg + white text
  - Neutral: `surface-2` bg + `text-muted` text
  - Verified: `primary` bg + white text

**Count Badge:**
- Min-width: 20px
- Height: 20px
- Padding: 2px 6px
- Radius: full
- Background: `danger`
- Text: white, label-sm

### Modals & Sheets

**Modal (Web):**
- Max-width: 500px (md), 700px (lg)
- Radius: 16px
- Padding: 24px
- Shadow: xl
- Overlay: rgba(0, 0, 0, 0.5)
- Animation: fade + scale(0.95)

**Sheet (Mobile):**
- Bottom aligned
- Radius: 16px (top only)
- Padding: 24px
- Max-height: 90vh
- Handle: 32px wide, 4px tall, `border` color

### Navigation

**Bottom Nav (Mobile):**
- Height: 60px
- Background: `surface`
- Shadow: 0 -2px 8px rgba(0, 0, 0, 0.08)
- Items: 4-5 max
- Active: `primary` color + icon fill
- Inactive: `text-muted`

**Header (Web):**
- Height: 64px
- Background: `surface`
- Border-bottom: 1px `border`
- Padding: 0 24px
- Sticky: top

### Lists

**List Item:**
- Min-height: 56px
- Padding: 12px 16px
- Border-bottom: 1px `border`
- Hover: background `surface-2`
- Active: background `primary-light`

**Section Header:**
- Font: title-sm (16px Medium)
- Color: `text-muted`
- Text-transform: uppercase
- Letter-spacing: 0.5px
- Padding: 8px 16px

---

## Icons

**Library:** Lucide Icons (web) / Material Icons (mobile)

**Sizes:**
```
sm:  16px  - Inline with text
md:  20px  - Button icons
lg:  24px  - Navigation, headers
xl:  32px  - Feature cards, empty states
2xl: 48px  - Hero, onboarding
```

**Colors:**
- Default: `text-muted`
- Active: `primary`
- Semantic: success/warning/danger colors

---

## Animation & Transitions

**Duration:**
```
fast:   150ms  - Micro interactions (hover, focus)
normal: 200ms  - Standard (button press, toggle)
slow:   300ms  - Complex (modal open, page transition)
```

**Easing:**
```
ease-out:  cubic-bezier(0, 0, 0.2, 1)     - Enter
ease-in:   cubic-bezier(0.4, 0, 1, 1)     - Exit
ease:      cubic-bezier(0.4, 0, 0.2, 1)   - Standard
```

**Common Patterns:**
- Hover: scale(1.02) + shadow increase
- Press: scale(0.98)
- Modal enter: fade + scale(0.95) → scale(1)
- Modal exit: fade + scale(1) → scale(0.95)
- Toast: slide-in-right + fade

---

## Responsive Breakpoints

```
mobile:    0px     - 639px   (default)
tablet:    640px   - 1023px  (sm)
desktop:   1024px  - 1279px  (md)
wide:      1280px+ (lg)
```

**Container Max-widths:**
```
mobile:   100%
tablet:   640px
desktop:  1024px
wide:     1280px
```

---

## Accessibility

**Color Contrast:**
- Text on background: minimum 4.5:1 (WCAG AA)
- Large text: minimum 3:1
- Interactive elements: 3:1 against adjacent colors

**Focus States:**
- Visible focus ring: 3px `primary` with 3px offset
- Never remove focus styles

**Touch Targets:**
- Minimum: 44x44px (mobile)
- Recommended: 48x48px

**Screen Readers:**
- Proper semantic HTML
- ARIA labels where needed
- Skip links for navigation

---

## Usage Guidelines

### Do's ✅
- Use primary for main CTAs (max 1-2 per screen)
- Use accent sparingly for special actions
- Maintain consistent spacing (8pt grid)
- Test in both light and dark modes
- Provide loading states for async actions
- Show empty states with helpful CTAs
- Use semantic colors for status (success/warning/danger)

### Don'ts ❌
- Don't use multiple accent colors per screen
- Don't mix border radius styles inconsistently
- Don't use shadow on every element (use sparingly)
- Don't override semantic colors (red always danger)
- Don't create custom colors outside system
- Don't use text smaller than 12px (body-sm minimum)
- Don't forget hover/active/disabled states

---

## Platform-Specific Notes

### Web (Tailwind)
- Use CSS variables for tokens
- Implement with Tailwind config
- Support hover states
- Keyboard navigation essential

### Mobile (Flutter)
- Use ThemeData + extensions
- Material Design 3 foundation
- Touch-optimized (48px minimum)
- Bottom navigation preferred over tabs

---

## Implementation Priority

1. **Phase 1 - Foundation:**
   - Color tokens
   - Typography scale
   - Spacing system

2. **Phase 2 - Components:**
   - Buttons (all variants)
   - Inputs & forms
   - Cards

3. **Phase 3 - Patterns:**
   - Navigation
   - Modals & sheets
   - Lists & grids

4. **Phase 4 - Polish:**
   - Animations
   - Empty states
   - Loading states
   - Error states
