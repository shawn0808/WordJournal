# UI Improvement Plan

## Definition Popup
- [x] Rounded corners with subtle shadow — modern macOS appearance
- [x] Better typography — proper font weights, spacing, and hierarchy for word, phonetic, POS, definitions
- [x] Visual separator between different parts of speech
- [x] Hover effect on + buttons (color/scale animation)
- [x] Loading state — show a spinner while fetching definitions
- [x] Fade in/out animations
- [x] Position popup near selected word

## Journal View
- [x] Alternating row colors for better readability
- [x] Empty state — friendly message when journal is empty
- [x] Better toolbar design — polished search field, styled buttons with hover effects, entry count badge
- [x] Confirmation dialog before deleting an entry

## Menu Bar Dropdown
- [x] Visual polish — subtle icons, better spacing, word count badge
- [x] Recent lookups — show last 5 words for quick re-access

## Synonyms & Antonyms
- [ ] Display synonyms/antonyms in the Definition Popup (below each definition, lighter style)
- [ ] Include synonyms/antonyms when saving to Journal (add columns to WordEntry + JournalStorage)
- [ ] Free Dictionary API already returns structured synonyms/antonyms — just display them
- [ ] NOAD (macOS system dictionary) does not provide synonyms (thesaurus is a separate dictionary)
- [ ] Wiktionary — would need extra parsing or a separate call for synonym data

## Word Recommendations
- [ ] Recommend 3 new words/phrases based on past lookups and journal entries
- [ ] Display in Menu Bar Dropdown as a "Discover" section; tapping a word triggers a lookup
- [ ] **Option A — Datamuse API** (free, no key needed)
  - [ ] Use `api.datamuse.com` for related/triggered words
  - [ ] Flow: take last 3–5 recent lookups → query for related words → filter out journal entries → pick 3
- [ ] **Option B — LLM API** (most intelligent, requires API key)
  - [ ] Call OpenAI/Claude API with recent lookups + journal words as context
  - [ ] Prompt: "Given these recently looked-up words: [...], suggest 3 interesting English words the user might enjoy learning. Include a brief reason for each."
  - [ ] Store API key in Preferences (user provides their own key)
  - [ ] Show the "why" reason alongside each recommendation for richer context
  - [ ] Could also power other features: smarter example sentences, usage tips, word origin summaries
- [ ] Consider fallback: bundled curated word list (GRE/SAT/vocabulary builder) for offline use

## General
- [x] Consistent color scheme — accentBlue (0.35, 0.56, 0.77) used across all views
- [x] Dark mode support — uses system colors (NSColor.windowBackgroundColor, .secondary, etc.)
- [x] Smooth animations — fade in popup, hover effects, animated deletions
