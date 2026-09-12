# HisabPro --- Mobile App Design Specification

## 1. Product Identity

**App Name:** HisabPro\
**Tagline:** Fast • Accurate • Always Yours

### Brand Direction

-   Modern financial/calculation utility
-   Clean, trustworthy, lightweight
-   Mobile-first
-   Blue and white primary visual identity
-   Rounded cards and controls
-   Strong hierarchy with generous spacing
-   Minimal decoration; prioritize readability and speed

------------------------------------------------------------------------

## 2. Screen

**Primary screen:** Calculation Entry / Dashboard

**Recommended design target:** - Mobile portrait - 390--430 px wide -
Responsive for smaller Android/iOS screens - Safe-area aware -
Scrollable content - Bottom action area remains easy to reach

------------------------------------------------------------------------

## 3. Color System

  Token                Suggested Value   Usage
  -------------------- ----------------- -------------------------------
  Primary Blue         `#2563EB`         Main buttons, active controls
  Deep Navy            `#17365D`         Headings and important text
  Cyan Blue            `#22C7F2`         Logo accent / secondary brand
  Background           `#F4F8FE`         App background
  Surface              `#FFFFFF`         Cards and inputs
  Border               `#D9E1EC`         Input/card borders
  Muted Text           `#64748B`         Secondary labels
  Success Green        `#16A34A`         Lene Aaj / positive result
  Success Background   `#ECFDF3`         Final result card
  Warning Orange       `#F59E0B`         Percentage calculation
  Danger Red           `#DC2626`         Delete actions

Use the exact values as a starting point; allow small adjustments for
accessibility and contrast.

------------------------------------------------------------------------

## 4. Typography

Use a clean modern sans-serif font such as:

**Inter / SF Pro / Roboto**

### Hierarchy

-   App name: 34--40 px, bold
-   Page/title text: 20--24 px, semibold
-   Section heading: 17--19 px, semibold
-   Body text: 15--17 px
-   Input text: 16--18 px
-   Result values: 24--30 px, bold
-   Small helper text: 13--15 px

Avoid overly thin text.

------------------------------------------------------------------------

# 5. Header

Create a compact top header.

### Left

HisabPro logo/icon.

### Center/Right

**HisabPro**

-   `Hisab` in deep navy
-   `Pro` in primary/cyan blue

Under the name:

**Fast • Accurate • Always Yours**

### Right

Settings icon inside a light circular button.

Keep the header visually light and avoid excessive vertical space.

------------------------------------------------------------------------

# 6. Calculation Title

Use a single large card/input.

Label:

**Calculation Title**

Example value:

**Modi bhai 96% 4**

Include: - Clear `×` icon on the right when text exists - Large touch
target - White surface - 1 px light border - 12--16 px corner radius

------------------------------------------------------------------------

# 7. Settlement Type

Section heading:

**Settlement Type**

Use a segmented control:

  Lene h   Dene h
  -------- --------

### Active State

-   Primary blue background
-   White text
-   Small directional arrow icon

### Inactive State

-   White/light background
-   Navy text
-   Light border

The selection controls the wording of the final result.

------------------------------------------------------------------------

# 8. Bracket Rate

Place the bracket-rate selector beside the settlement control on larger
screens.

Example:

**% Bracket Rate**\
**96% ▼**

The first version should default to **96%**.

Future selectable options:

-   96%
-   95%
-   90%
-   80%

The UI should make it clear that the percentage is applied to the total
bracket.

------------------------------------------------------------------------

# 9. Entry Table

Use a single clean card rather than separate large cards for every row.

### Table Header

  \#   Name   Amount (₹)   Bracket   Delete
  ---- ------ ------------ --------- --------

### Row Example

| 1 \| Sb. \| 8490 \| 30 \| 🗑 \|
| 2 \| Gw. \| 5880 \| 35 \| 🗑 \|
| 3 \| Db. \| 7500 \| 81 \| 🗑 \|

Each editable field should have: - White background - Light gray/blue
border - 10--12 px radius - Comfortable padding - Numeric keyboard for
Amount and Bracket

### Name

Can be a text/dropdown field.

### Amount

Accept: - Whole numbers - Decimal numbers - Comma-formatted numbers

Examples: - `8490` - `8,490` - `11732.50`

### Bracket

Accept decimals.

Example:

`82.5`

### Delete

Use a small red trash icon.

Do not make the delete icon visually dominant.

------------------------------------------------------------------------

# 10. Add Row

At the bottom of the table:

**＋ Add Row**

Use a light-blue filled button/card.

Requirements: - Full-width inside the table card - Large touch target -
Simple plus icon - No unnecessary animation

Allow unlimited rows, while keeping the UI usable with many entries.

------------------------------------------------------------------------

# 11. Live Preview

Show a subtle live calculation preview below the table.

Example:

**Preview: ₹19,065 lene aaj**

The preview should update whenever Amount, Bracket, percentage, or
settlement type changes.

Use muted text so it does not compete with the main Calculate button.

------------------------------------------------------------------------

# 12. Calculation Logic

The calculation engine must be completely separate from the UI.

For every valid row:

``` text
TOTAL AMOUNT = SUM(all Amount values)

TOTAL BRACKET = SUM(all Bracket values)

PASSING = TOTAL BRACKET × selected rate

LENE/DENE = TOTAL AMOUNT − PASSING
```

For the default 96% mode:

``` text
PASSING = TOTAL BRACKET × 96
```

### Exact Test Data

``` text
Sb.   8490      30
Gw.   5880      35
Db.   7500      81
Dm.   7570      50
Sg.   7337      211
Ag.   11732     140
Fb.   16253     65
Al.   10270     100
Gb.   11500     82.5
Dw.   10350     35
Gl.   15700     190
Ds.   8195      40
```

Expected:

``` text
TOTAL AMOUNT = 120,777
TOTAL BRACKET = 1,059.5
PASSING = 1,059.5 × 96 = 101,712
LENE AAJ = 120,777 − 101,712 = 19,065
```

The application must return:

**₹19,065**

------------------------------------------------------------------------

# 13. Summary Cards

After calculation, display four compact summary cards.

### Card 1

**Total Amount**

`₹120,777`

### Card 2

**Total Bracket**

`1,059.5`

### Card 3

**96% of Bracket**

`₹101,712`

### Card 4 --- Highlighted

**Lene Aaj**

`₹19,065`

The final card should use a subtle green background and green value to
make the settlement amount immediately visible.

Use a 2 × 2 grid on mobile where space permits.

------------------------------------------------------------------------

# 14. Bottom Actions

Use three primary actions.

### Secondary Row

**Clear All**\
and\
**New Calculation**

These should be secondary/light buttons.

### Primary Action

Large full-width blue button:

**▣ Calculate**

This is the main action and should have: - Primary blue background -
White text - 16--18 px bold/semibold text - 52--60 px height - 14--16 px
radius

------------------------------------------------------------------------

# 15. Results Screen

After pressing Calculate, open a clean results view.

### Header

Back/Edit button on left.

Title:

**Result**

Share icon on right.

### Calculation Name

Show:

**Modi bhai 96% 4**

### Summary

Display:

``` text
Total Amount       ₹120,777
Total Bracket      1,059.5
96% of Bracket     ₹101,712
Lene Aaj           ₹19,065
```

Make **Lene Aaj** the strongest visual element.

------------------------------------------------------------------------

# 16. Calculation Details

Provide a collapsible or compact calculation explanation:

``` text
Total Amount = 120,777

Total Bracket = 1,059.5

96% of Bracket
1,059.5 × 96 = 101,712

Lene Aaj
120,777 − 101,712 = 19,065
```

This is important because users need to verify the calculation quickly.

------------------------------------------------------------------------

# 17. Copy Message

At the bottom of the results screen provide a large green/blue action:

**📋 Copy Message**

When clicked: 1. Generate the final formatted message. 2. Copy it to the
clipboard. 3. Change button temporarily to **✓ Copied**. 4. Show a small
confirmation such as **Message copied!**

### Message Format

``` text
Modi bhai 96% 4

Sb. 8490 (30)
Gw. 5880 (35)
Db. 7500 (81)
Dm. 7570 (50)
Sg. 7337 (211)
Ag. 11732 (140)
Fb. 16253 (65)
Al. 10270 (100)
Gb. 11500 (82.5)
Dw. 10350 (35)
Gl. 15700 (190)
Ds. 8195 (40)

TOTAL 120777

PASSING 1059.5 × 96 = 101712

LENE AAJ = 19065
```

Do not add unnecessary symbols or extra text to the copied message.

------------------------------------------------------------------------

# 18. Validation

Before calculation:

-   Reject invalid Amount values.
-   Reject invalid Bracket values.
-   Allow decimal brackets.
-   Ignore completely empty unused rows or clearly flag them.
-   Never output `NaN`.
-   Never output `undefined`.
-   Never output `Infinity`.
-   Never silently convert invalid text into zero.
-   Show a clear inline error beside the invalid field.

All arithmetic must be performed programmatically.

------------------------------------------------------------------------

# 19. Number Formatting

Use Indian number formatting.

Examples:

``` text
120777 → 1,20,777
101712 → 1,01,712
19065 → 19,065
1059.5 → 1,059.5
```

For the UI, use:

**₹1,20,777**

For the copied message, follow the plain-number format specified in the
Copy Message section unless the user changes the format later.

Do not round away meaningful decimal values.

------------------------------------------------------------------------

# 20. Spacing

Use an 8-point spacing system.

Recommended spacing:

-   Page horizontal padding: 20--24 px
-   Header bottom margin: 20--28 px
-   Card gap: 12--16 px
-   Section gap: 18--24 px
-   Input padding: 14--16 px
-   Button height: 52--60 px
-   Card radius: 16--20 px
-   Input radius: 10--14 px

The goal is to prevent the interface from feeling crowded.

------------------------------------------------------------------------

# 21. Design Principles

### Reduce Clutter

Do not put every control into its own oversized card.

### Strong Hierarchy

The user should immediately understand:

1.  What calculation they are doing
2.  What values they entered
3.  What the result is
4.  What amount they need to take/give

### Progressive Disclosure

Keep advanced information such as calculation details visually
secondary.

### Touch Friendly

All buttons and fields should be comfortable to use with one hand.

### Fast Workflow

Target workflow:

``` text
Open App
↓
Enter Title
↓
Enter Rows
↓
Calculate
↓
Check Result
↓
Copy Message
```

------------------------------------------------------------------------

# 22. Empty State

When starting a new calculation, show a simple empty state:

**Start a New Hisab**

`Add your first row to begin.`

Button:

**＋ Add Row**

Do not display a large empty table.

------------------------------------------------------------------------

# 23. Responsive Behavior

### Mobile

-   Single-column layout
-   Table can become horizontally scrollable if necessary
-   Keep Calculate button prominent
-   Summary cards use 2 × 2 layout

### Tablet/Desktop

-   Center the application content
-   Maximum content width around 900--1100 px
-   Expand the table naturally
-   Use more horizontal space without increasing visual clutter

------------------------------------------------------------------------

# 24. Persistence

Save the current calculation locally.

Persist: - Calculation title - Settlement type - Bracket rate - Rows -
Amounts - Brackets

If the user refreshes the app, restore the current calculation.

Add:

**New Calculation**

to intentionally clear the current calculation and start fresh.

------------------------------------------------------------------------

# 25. Accessibility

-   Minimum touch target: approximately 44 × 44 px
-   Maintain readable contrast
-   Do not communicate information through color alone
-   Use accessible labels for icons
-   Support keyboard navigation on desktop
-   Inputs must have visible labels
-   Error messages must be readable and associated with their fields

------------------------------------------------------------------------

# 26. Visual Style Summary

The final interface should feel like:

**Modern banking app + simple calculator + personal hisab notebook**

Avoid: - Excessive shadows - Too many colors - Large decorative cards -
Tiny controls - Dense information blocks - Unnecessary gradients -
Complex navigation

Prefer: - White surfaces - Soft blue background - Primary blue actions -
Green final result - Clear typography - Consistent rounded corners -
Generous whitespace - Simple icons

------------------------------------------------------------------------

# 27. Design Acceptance Criteria

The design is complete when:

-   The screen no longer feels clustered.
-   A user can enter many rows quickly.
-   The Calculate button is immediately obvious.
-   The final Lene/Dene amount is impossible to miss.
-   Calculation details are easy to verify.
-   Copy Message is one tap away.
-   The exact test data produces **₹19,065**.
-   The UI works comfortably on a typical Android phone.
-   The visual identity consistently uses **HisabPro** branding.
