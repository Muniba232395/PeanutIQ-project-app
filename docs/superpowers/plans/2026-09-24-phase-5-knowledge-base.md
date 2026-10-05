# Phase 5: Knowledge Base — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. TDD per task. Plan format as ruled in Phase 2.

**Goal:** Port `KnowledgeBase.jsx` for farmers as the Knowledge tab:
- search, and a Search / Ask AI toggle, where Ask AI uses the website's canned answers;
- category chips with counts;
- article cards;
- the article detail screen (`/kb/:id`).

**Architecture:**
- **Data:** `KnowledgeRepository.fetchPublished()` → `GET /knowledge/articles`. Farmers get published articles only, as in the website's KnowledgeContext.
- **List:** `articlesProvider`, keyed on the user.
- **Search and categories:** filtered on the device, as on the website.
- **Ask AI:** `KbAskAiRepository` is the fake part: a 2 s delay, then a keyword match.
- **Detail:** a pushed route inside the Knowledge branch. The article is looked up by id in the loaded list.

**Spec:** §7 Knowledge Base.

## Rulings

- **Edit / Delete are not shown to farmers.** The spec copied the website, which shows them when `article.author == user.name`. But the backend (`knowledge.py`) returns 403 for farmers on PUT and DELETE, so on the website those buttons silently fail. Only researchers can create articles, so a farmer can match an author only by coincidence. Showing buttons that always fail would be worse than the website.
- **No Create button**, as in the spec: the website shows it only to researchers.

## Global Constraints

Earlier phases apply, plus:

**Categories:**
- The categories come from `kb.categories` (a list of `{id, name, count}`), read with `Translations.raw`.
- "All Articles" is `kb.allArticles`.
- Filtering compares `article.category` with the category *name in the current language*, as on the website. Switching language resets the selection to "All".
- **Chip style:**
  - rounded-xl, px16 py8, 14 bold;
  - active: forest fill, white text, shadow-md;
  - inactive: white, earth border, charcoal text;
  - count pill (12, weight 600, rounded-full): white with forest text when active; earth with forest text otherwise.
- The chips scroll sideways, as on the website at phone width.

**Search (on the device):** a case-insensitive match on title **or** excerpt.

**Search box:**
- A flat card, padding 8. The input (16, weight 500, slate-900) has a leading icon: `search` in slate-400, or `sparkles` in forest in AI mode.
- The placeholder is `kb.searchPlaceholder`, or `kb.searchAiPlaceholder` in AI mode.
- A full-width toggle sits below: a sand track with a slate-200 border and radius 8.
  - Active Search: white, shadow-sm, slate-900 text.
  - Active Ask AI: forest fill, white text.
  - Inactive: slate-600.
- In AI mode, submitting from the keyboard asks the AI.

**Ask AI (fake):**
- Waits 2 s, then picks an answer:
  - `leaf spot`, `بیماری` or `دھبے` → `kb.aiResponses.disease`;
  - `seed`, `sow` or `بیج` → `seed`;
  - anything else → `general`.
- The match is on the lower-cased query.
- **Panel:** purple-50 fill, purple-100 border, radius 16, padding 24.
  - While thinking: a spinning `loader` and `kb.aiThinking` in purple-700.
  - Done: a `sparkles` icon, the `kb.aiRec` title (bold, purple-900) and a close X (purple-400); the answer (14, purple-800); an `info` icon with `kb.derivedInfo` (12, purple-600).

**Article card:**
- White, earth border, radius 16, padding 24, shadow `0 4px 20px -4px rgba(0,0,0,.05)`.
- A decorative forest/5 quarter-circle (128) at the top end.
- **Top row:**
  - category pill: forest fill, white 10 w900 uppercase, widest tracking, radius 8;
  - author: `bookOpen` icon in forest at 70%, 12 bold slate-500;
  - date pill: 12 bold slate-400, sand fill, slate-100 border.
- Title: 20 w900, slate-800.
- Excerpt: 14 weight 500, slate-600, 2 lines.
- An earth/60 divider, then "Read Article" (`kb.app.readArticle`, 14 bold forest) with a 32 px forest/10 circle holding a chevron that flips in RTL.

**Dates:** `M/d/yyyy`, local (the website's `new Date(created_at).toLocaleDateString()`).

**Detail:**
- A flat card, padding 24.
- A back row (`arrowLeft` flips in RTL; `kb.back`, 14 weight 500, gray-500).
- Meta: the category pill (forest, 12 bold uppercase), author and date, 14 gray-500.
- Title: 30 w900, gray-900.
- Excerpt: 18 italic gray-600, with a 4px gray-200 start border.
- Content: 18, gray-800, line height 2.

**Empty:** a flat card with a `bookOpen` icon (48, slate-300), `kb.noArticles` (20 bold) and `kb.tryAdjusting`.

**New keys:**

| Key | en | ur |
|---|---|---|
| `kb.app.readArticle` | Read Article | مضمون پڑھیں |
| `kb.app.notFound` | This article is no longer available. | یہ مضمون اب دستیاب نہیں ہے۔ |

## Review Focus

1. **The farmer switches language while a category is selected.** Expected: the selection resets to All and articles still show. Test: "language switch resets category".
2. **Ask AI again while an answer is showing.** Expected: the new answer replaces the old one after thinking. Test: "second question replaces answer".
3. **An article is deleted on the server while the farmer is reading its link.** Expected: "no longer available", with a back button, not a crash. Test: "unknown article id shows not found".
4. **Search with leading or trailing spaces.** Expected: behaves like the website, which doesn't trim; documented here, no special handling.
5. **Long Urdu titles at 1.5× text.** Expected: no overflow. Test: small-screen Urdu.

---

### Task 1: Data and fake AI

**Files:**
- `lib/features/knowledge/data/article.dart`: `Article {id, title, category, excerpt, content, author, createdAt}`.
- `lib/features/knowledge/data/knowledge_repository.dart`: `fetchPublished()`.
- `lib/features/knowledge/data/kb_ask_ai_repository.dart`: `Future<String> ask(String query, Translations t)`, plus `kbAiDelayProvider`.
- `lib/features/knowledge/knowledge_providers.dart`: `articlesProvider`; `filterArticles(List<Article>, {String query, String? category})`; `kbCategories(Translations)` returns `List<({int id, String name})>`.
- `tool/translations/phase5.json`.
- Tests: `test/features/knowledge/knowledge_data_test.dart`.

**Tests:** parse; the request is `GET /knowledge/articles` with no query; filter by title, by excerpt and by category, case-insensitively; `kbCategories` reads the list in both languages; ask-AI keyword routing (EN and UR words) with a zero delay.

### Task 2: List screen

**Files:** `lib/features/knowledge/knowledge_screen.dart`, `widgets/article_card.dart`, `widgets/category_chips.dart`, `widgets/kb_search_box.dart`, `widgets/ai_answer_panel.dart`; router `/kb`.

**Tests:**
- "lists published articles with category, author, date".
- "search filters by title and excerpt".
- "category chip filters and shows counts".
- "Ask AI shows thinking then the matching answer".
- "second question replaces answer".
- "close hides the AI panel".
- "language switch resets category".
- "empty state".
- "error shows Retry".
- "fits 360x640 at 1.5x in Urdu".

### Task 3: Detail screen

**Files:** `lib/features/knowledge/article_screen.dart`; route `/kb/:id`.

**Tests:** "tapping a card opens the article"; "back returns to the list with the search kept"; "unknown article id shows not found".

### Task 4: Emulator check

Add `GET /knowledge/articles` to the mock (3 articles across categories). Screenshots of the list, Ask AI and the detail.
