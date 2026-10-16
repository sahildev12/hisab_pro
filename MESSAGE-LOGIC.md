# WhatsApp bet message logic

Shared reference for parsing group messages. **Senders change punctuation and spelling**; meaning stays the same. Use this doc when building or testing parsers.

---

## Three systems (do not mix)

| ID | Table | Name | Typical message shape |
|----|-------|------|------------------------|
| **A** | **1–100** | **Single pricing** | One table number + ₹ on that number (`11=5`, `11+10`, …). |
| **B** | **0–9** (bundle) | **Joda cut** | Digit string + keywords + price (`12345 joda cut into 15`, `12345 JK 15`, …). |
| **C** | **0–9** (bundle) | **Crossing** | Long digit string + separator + price, **no joda keywords** (`12357890=3`, `01234678=2`). |

**Critical:** `12357890=3` is **crossing**, **not** joda cut — even though it looks like `digits=price`.

All three mean “client money on numbers”. **A** = one table slot per line. **B** and **C** share the same **formula** but **`n` is counted differently**.

---

## Table number alias (1–100 only)

For **single pricing (A)** only:

| Written | Meaning |
|---------|---------|
| `00` | Same slot as **100** |
| `100` | Same slot as **00** |

Normalize before storing or summing single lines.

---

## A. Single pricing (table 1–100)

### Meaning

1. **First part:** table number **1–100** (often written `03`, `09`; apply **00 ↔ 100**).
2. **Second part:** client **₹** paid on **that one number only**.

Order is always **table number first, price second**. Separators vary by sender.

### Format examples (not exhaustive)

| Line | Parsed as |
|------|-----------|
| `11=5` | Table **11**, ₹**5** |
| `11+10` | Table **11**, ₹**10** |
| `11.25` | Usually table **11**, ₹**25** (confirm decimals vs separator with team) |

### Output

`{ type: 'single', tableNumber: 1..100, amountRs: number }`

---

## B. Joda cut (table 0–9 bundle)

### Meaning

- Left: **digit string** using digits **0–9** only (shop “0–9 table” — client spread money across those digits).
- Right: **client price** ₹.
- Middle words are **not reliable**; treat as hints.

### Keyword examples (same intent)

```
12345 Joda Cut Into 15
12345 JK 15
12345 JC 15
12345 Joda 15
123545 Jara Kat 15
```

Also watch for typos: `jode`, `ket`, etc. — map to joda when context matches.

### Minimum length

- Need **at least 3 digits** in the left string (`379`, `5392`, `12345`, …).

### Length 3 — all digits must differ

For **exactly 3 digits**, **no digit may repeat** (e.g. `379`, `482` OK; `464` needs team rule — see open questions).

### Length 4+ — pairs can exist

With **4 or more digits**, repeats are allowed in the string (e.g. `5855` is valid). For **joda `n`**, **cancel duplicate digits in pairs** (see below).

### Step-by-step math (team wording)

Given digit string (after joda `n` rules) with effective count **`n`**, and client price **`P`**:

1. **Square:** `n × n`
2. **Subtract n:** `(n × n) − n` → call this **factor** (same as `n × (n − 1)`)
3. **Total:** `P × factor`

| Digits (joda `n`) | n×n | − n | factor | P | Total |
|-------------------|-----|-----|--------|---|-------|
| `12345` → n=5 | 25 | 5 | **20** | 15 | **300** |
| `482` → n=3 | 9 | 3 | **6** | 15 | **90** |
| `4574` → n=3 (one 4 pair cancelled) | 9 | 3 | **6** | 15 | **90** |

### How joda `n` is counted (pair rule)

**Joda cut:** same-digit **pairs do not count** the way crossing counts them.

- Shop rule: **cancel one digit from each fully matched pair** of the same digit in the string.
- Example: `4574` → two 4s → cancel one → effective **n = 3** (not 4).
- Pairs like **11, 22, …, 99, 00** in the digit string are handled under this rule ( **`00` here = two zeros**, not table 100).

**Crossing uses full length; joda does not** — same formula, different `n`.

### Output

`{ type: 'joda', digitsRaw, clientPriceRs, n, factor, lineTotalRs }`

Only when joda keywords / agreed joda patterns match.

---

## C. Crossing (table 0–9 bundle)

### Meaning

- **Long digit string** (0–9, length **≥ 3**) + separator + **client price**.
- **No** joda / JK / JC / “cut into” / “jara kat” wording.
- Examples: **`12357890=3`**, **`01234678=2`**.

### How crossing `n` is counted

**Crossing:** **count every digit** in the left string — **including** same-digit pairs (`11`, `55`, `00`, `99`, …).

| Line | Digits | n | factor (n²−n) | P | Total |
|------|--------|---|---------------|---|-------|
| `12357890=3` | 12357890 | 8 | 56 | 3 | **168** |
| `01234678=2` | 01234678 | 8 | 56 | 2 | **112** |
| `4574=…` (crossing) | 4574 | **4** | 12 | … | … |

Same formula as joda:

```
n       = digit count (crossing — include all digits)
factor  = n × n − n
total   = clientPrice × factor
```

### Output

`{ type: 'crossing', digitsRaw, clientPriceRs, n, factor, lineTotalRs }`

---

## Joda vs crossing (one glance)

| | **Joda cut** | **Crossing** |
|---|--------------|--------------|
| Keywords | joda, JK, JC, cut into, jara kat, … | None required |
| Typical shape | `12345 … 15` | `12357890=3` |
| Same pairs (11, 55, 00, 99, …) | **Not** counted like full length — cancel pairs for `n` | **Counted** — `n` = string length |
| Example `4574` | n = **3** | n = **4** |
| Formula | price × (n² − n) | price × (n² − n) |

---

## Quick decision tree

```
Line
├── One table number 1–100 + price?  (apply 00 ↔ 100)
│   └── → A: Single pricing
├── Digit string (len ≥ 3) + price + joda keywords (JK, JC, joda, cut into, jara kat, …)?
│   └── → B: Joda cut  (n: pair cancellation)
└── Digit string (len ≥ 3) + = / + / . + price, NO joda keywords?
    └── → C: Crossing  (n: count all digits)
```

---

## Reference samples (WhatsApp groups)

Examples seen in production chats (for parser tests — **not** full archive):

| # | Line | Type | Notes |
|---|------|------|-------|
| 1 | `12357890=3` | **Crossing** | n=8 → 3×56 = ₹168 |
| 2 | `01234678=2` | **Crossing** | n=8 → 2×56 = ₹112 |
| 3 | `12345 joda cut into 15` | **Joda** | n=5 → 15×20 = ₹300 |
| 4 | `joda 22 33 44 (30)` | **Joda?** | Different layout — separate pattern (open) |
| 5 | `469=75jode ket` | **Unclear** | Typo / mixed — needs rule |

Older messages may exist only on phone (“load older messages” on Web). Counts from Web scans are **partial**.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-10-16 | Initial: single pricing, joda, n²−n, duplicate cancel examples. |
| 2026-10-16 | **Crossing** split from joda; `12357890=3` is crossing. Joda vs crossing pair rules. **00 ↔ 100** for single table. |
| 2026-10-16 | Step-by-step joda math, keyword variants, min length 3, reference WhatsApp samples, decision tree. |

---

## Open questions (confirm with team)

1. **Joda:** `464` (3 chars with repeat) — reject line vs compute `n` after cancel.
2. **Single:** `11.25` — always table `11` + ₹25 vs decimal amount.
3. **`joda 22 33 44 (30)`** — new parser branch vs ignore.
4. **`469=75jode ket`** — crossing with trailing junk vs invalid.
5. **Crossing:** only `=` or also `+`, `.`, spaces before price?

---

## Backup

Before changing parsers in the app, take a project backup (see `backups/` folder or repo tag on `athen`).
