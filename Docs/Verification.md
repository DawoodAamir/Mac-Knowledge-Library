# Verification

October 1, 2026: Debug core checks passed for bounded source retrieval/page references, archive filtering, atomic persistence, stale edit rejection, corrupt-file preservation, and UTF-8 import.

Release core tests (four checks), Release app build, and native UI test compilation passed. A standalone check using the production on-device profile returned a bounded draft mentioning the original source’s PDF export instruction (161 characters). This is a smoke check, not a grounding or quality certification.

The hosted native workflow is pending; local Mac UI runner initialization is unavailable with this machine’s current development-tools security setting. No security setting was changed.

Manual checks remain for VoiceOver, extended text sizes, large real PDFs, Spotlight indexing propagation, tool retrieval quality, and model availability changes. Generated answers need human source review.
