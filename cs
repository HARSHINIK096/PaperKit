## IMPLEMENTATION DECISIONS — APPROVED

Proceed with the following decisions. These are the final implementation requirements.

### 1. Backend Expansion — APPROVED

**Approved:** Add the new academic AI endpoints to the FastAPI backend in:

`Services/routers/ai.py`

Implement these endpoints as real backend functionality:

* `/ai/analyze-research`
* `/ai/literature-review`
* `/ai/research-gaps`
* `/ai/extract-citations`
* `/ai/format-citation`
* `/ai/study-notes`
* `/ai/generate-quiz`
* `/ai/generate-flashcards`
* `/ai/generate-mindmap`
* `/ai/generate-presentation`

The Flutter application should consume these endpoints through the existing API/service architecture.

### Backend Requirements

* Reuse the existing AI provider architecture wherever possible.
* Inspect the current Gemini/Groq/other provider implementation before creating new service logic.
* Do not duplicate existing AI infrastructure unnecessarily.
* Use structured request and response models.
* Validate all incoming parameters.
* Validate and sanitize AI responses before returning them to Flutter.
* Handle malformed AI responses properly.
* Return meaningful HTTP errors for provider failures, invalid documents, missing input, parsing failures, and unsupported operations.
* Never return fake success responses.
* Never return mock/sample AI results.
* Never hardcode research analysis, citations, references, quiz questions, flashcards, summaries, or other document-derived content.
* AI output must be grounded in the actual document content supplied by the user.

If the backend cannot produce a reliable result, return an actual error or an explicit insufficient-data response rather than fabricated content.

---

# 2. Academic Tool UI — APPROVED

**Approved:** Do NOT force the academic tools into the existing `ToolFlowScaffold` upload → configure → process → download pattern.

The academic tools require structured, interactive results.

Use:

`AppShell + custom academic result screens`

Follow the existing architectural and visual patterns from screens such as:

* `OCRScreen`
* `SummarizePDFScreen`

However, do not blindly copy those screens.

First inspect the existing implementation and reuse:

* AppShell
* theme
* AppColors
* typography
* spacing
* cards
* buttons
* file selection
* loading states
* error handling
* export/share mechanisms
* existing document preview components
* existing API service abstractions

The new screens must feel like a native part of PaperKit.

### Academic UX

The academic tools should support structured results rather than simply producing a downloaded file.

For example:

```text
Document
    ↓
Analyze
    ↓
Structured Result
    ↓
Sections / Findings / Citations / Tables / Insights
    ↓
User can inspect
    ↓
Export / Share / Save
```

Where applicable, allow:

* Expand/collapse sections
* Copy individual results
* Source/page references
* Regenerate
* Export
* Share
* Save
* Error recovery
* Empty states
* Loading states

Only implement actions that are genuinely supported by the underlying architecture.

---

# 3. Progress Handling — APPROVED

Do NOT use simulated progress for any new implementation.

The existing:

`ToolFlowScaffold._progressSimTimer`

may remain unchanged for existing tools to avoid unnecessary regressions.

However, **no new academic or newly implemented feature may use simulated progress.**

Do not create:

```text
10%
20%
35%
50%
75%
100%
```

using a timer when the application has no real progress information.

For API-based operations, use a genuine indeterminate processing state:

```text
Analyzing document...
Generating study notes...
Extracting citations...
Generating quiz...
```

The loading state must begin when the actual operation starts and end when the actual operation succeeds or fails.

Never display 100% until the real operation has completed.

For operations where genuine progress information is available, display the actual progress.

---

# 4. API Keys — EXISTING ISSUE, DO NOT EXPAND

The existing `api_config.dart` contains hardcoded API keys such as:

* `defaultGeminiApiKey`
* `defaultGroqApiKey`
* `defaultHfApiKey`

Do not introduce any additional hardcoded credentials.

Do not copy these keys into new files.

Do not expose credentials through new endpoints, logs, UI, exceptions, or API responses.

For this implementation, do not perform a broad credential-management refactor unless it is required for the new functionality.

Flag the existing hardcoded-key issue clearly in the final implementation report as a security concern.

---

# 5. ToolRegistry Deduplication — APPROVED

Proceed with the `ToolRegistry` refactor.

The goal is:

**One canonical ToolItem per tool.**

`AppTools.allTools` must not contain duplicate tool definitions.

Do not preserve duplicate ToolItems simply because they currently exist.

Before removing duplicates:

1. Search the entire codebase for every reference.
2. Identify the canonical tool ID.
3. Identify all routes and navigation references.
4. Identify any code depending on the existing objects.
5. Update those callers to use the canonical registry entry.

Do not assume that duplicate entries are harmless.

---

# 6. `getTopToolsForCategory()` — USE CANONICAL REGISTRY

Do NOT keep creating inline `ToolItem` objects inside:

`getTopToolsForCategory()`

The canonical registry must be the single source of truth.

For example, do not maintain:

```dart
ToolItem(
  id: 'ocr-document',
  ...
)
```

when the canonical registry already contains:

```text
ai-ocr
```

Instead:

```text
getTopToolsForCategory()
        ↓
ToolRegistry
        ↓
canonical ToolItem
```

All category screens, home screens, search, recommendations, featured tools, and contextual tool suggestions should resolve tools through the canonical registry.

---

# 7. ID BACKWARD COMPATIBILITY

Before removing old IDs, search the entire codebase for their usage.

If an old ID is used by:

* navigation
* deep links
* saved state
* recent tools
* favorites
* analytics
* persistence
* route resolution
* external references

then preserve compatibility through a controlled alias mechanism.

Example concept:

```text
legacy ID
    ↓
ToolRegistry alias resolution
    ↓
canonical ToolItem
```

Do NOT create a second ToolItem for the alias.

The registry must still contain only one canonical definition.

If an old ID has no meaningful usage anywhere in the codebase, migrate the caller to the canonical ID instead of unnecessarily keeping the alias.

---

# 8. NO MOCK / SAMPLE / HARDCODED DATA — ABSOLUTE RULE

This applies to BOTH Flutter and FastAPI.

Do not introduce:

* Mock data
* Sample data
* Demo data
* Fake API responses
* Fake AI responses
* Hardcoded document content
* Hardcoded research results
* Hardcoded citations
* Hardcoded references
* Hardcoded quiz questions
* Hardcoded flashcards
* Hardcoded research gaps
* Fake OCR output
* Fake tables
* Fake entities
* Fake presentation content
* Fake files
* Placeholder results

Static UI labels, icons, routes, tool IDs, configuration constants, and legitimate algorithmic constants are allowed.

**Document-derived or AI-derived content must always be generated/extracted from real input.**

---

# 9. NO FAKE FALLBACKS

Do not implement:

```text
API failure
    ↓
sample response
```

or:

```text
AI failure
    ↓
default result
```

or:

```text
processing failure
    ↓
show success
```

A fallback is allowed only when it is a genuine alternative implementation.

For example:

```text
Primary OCR
    ↓ failure
Local OCR
```

is acceptable if the local OCR genuinely processes the user's document.

This is not acceptable:

```text
Primary OCR
    ↓ failure
Fake OCR text
```

---

# 10. REAL DATA FLOW

Every new academic feature must follow a real data pipeline:

```text
User selects actual document
        ↓
Actual file loading
        ↓
Actual text extraction / OCR
        ↓
Actual document preprocessing
        ↓
Actual backend request
        ↓
Actual AI/provider processing
        ↓
Structured response
        ↓
Response validation
        ↓
Flutter model parsing
        ↓
Actual UI result
        ↓
Export / Share / Save
```

Do not bypass any stage with hardcoded data.

---

# 11. STRUCTURED AI RESPONSES

Do not return arbitrary unstructured strings when the feature requires structured information.

Use proper schemas/models for:

* Research analysis
* Literature review
* Research gaps
* Citations
* References
* Study notes
* Quiz questions
* Flashcards
* Mind maps
* Presentation slides

Flutter must parse and validate the response rather than blindly casting arbitrary JSON.

Malformed responses must result in a real parsing/error state.

---

# 12. SOURCE GROUNDING

Academic features must distinguish between information that is:

* Extracted from the document
* Derived from the document
* AI-inferred
* Suggested
* Unavailable

Never present an inference as an extracted fact.

Never invent missing metadata.

Never invent citations or references.

Whenever technically possible, preserve:

* page number
* section
* source text
* citation relationship
* document location

This is especially important for:

* Research Paper Analyzer
* Literature Review
* Research Gap Finder
* Citation Extractor
* Reference Checker
* Study Notes
* Quiz Generator
* Flashcards

---

# 13. DO NOT BREAK EXISTING PAPERKIT

Before modifying architecture:

1. Audit the existing codebase.
2. Understand current dependencies.
3. Understand current routes.
4. Understand existing services.
5. Understand current PDF processing.
6. Understand existing AI integration.
7. Understand current file handling.
8. Understand current state management.
9. Understand existing ToolFlowScaffold.
10. Understand current ToolRegistry/AppTools usage.

Reuse existing infrastructure wherever appropriate.

Do not rewrite working functionality merely to make the new implementation look cleaner.

---

# 14. FINAL VALIDATION

Before declaring the implementation complete, verify:

### Backend

* All academic endpoints exist.
* Endpoints accept real document input.
* AI providers are actually called.
* Responses are structured.
* Responses are validated.
* Provider failures are handled.
* Invalid input is handled.
* No fake responses exist.
* No hardcoded document-derived content exists.

### Flutter

* Every new tool has a canonical ToolItem.
* Every tool has a valid route.
* No duplicate canonical IDs exist.
* Existing routes still work.
* Search resolves canonical tools.
* Category filtering works.
* Featured tools work.
* `getTopToolsForCategory()` uses canonical registry entries.
* Academic screens use real backend data.
* No simulated progress is used in new tools.
* Loading/error/success states reflect actual execution.
* Export/share/save operate on real results.

### Codebase

Search for suspicious production implementations involving:

```text
mock
sample
dummy
demo
fake
placeholder
hardcoded result
fake response
fallback response
TODO
FIXME
UnimplementedError
```

Review each occurrence and remove any that violate these requirements.

Do not blindly remove legitimate test fixtures or static UI strings.

---

# FINAL DECISION

All three implementation questions are approved with the conditions above:

**1. Backend academic endpoints:** YES — implement them properly in FastAPI and connect Flutter to them.

**2. Academic custom UI:** YES — use `AppShell` and custom structured-result screens instead of forcing everything through `ToolFlowScaffold`.

**3. ToolRegistry:** YES — deduplicate the registry, migrate callers to canonical IDs, and use aliases only where genuine backward compatibility is required.

The highest priority is:

**REAL IMPLEMENTATION > FAKE COMPLETENESS**

Do not declare a feature complete unless it actually works with real user input.
