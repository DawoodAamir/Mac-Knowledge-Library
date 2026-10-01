# Verification

October 1, 2026: Debug core checks passed for bounded source retrieval/page references, archive filtering, atomic persistence, stale edit rejection, corrupt-file preservation, and UTF-8 import.

Release core tests (four checks), Release app build, and native UI test compilation passed. A standalone check using the production on-device profile returned a bounded draft mentioning the original source’s PDF export instruction (161 characters). This is a smoke check, not a grounding or quality certification.

The hosted native workflow passed on October 2, 2026: sample creation, source search, source inspection, archive, and exclusion after relaunch. [Successful run](https://github.com/DawoodAamir/Mac-Knowledge-Library/actions/runs/36913876776). The README screenshot comes from that run. Local UI runner initialization was unavailable; no security setting was changed.

Manual checks remain for VoiceOver, extended text sizes, large real PDFs, Spotlight indexing propagation, tool retrieval quality, and model availability changes. Generated answers need human source review.
