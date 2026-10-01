# Data handling

Imported text and metadata stay in the app's Application Support directory. Original files are read with temporary security-scoped access and never changed. There is no application-operated backend, telemetry, account, or external document service.

Optional answers use Apple's on-device language model. Questions and relevant excerpts are supplied to that model locally. Model readiness and Apple Intelligence settings govern availability.

Spotlight integration is off at launch. The explicit toggle makes imported documents discoverable in system search and creates plain-text copies within this app's sandbox. The model's file search scope is restricted to that folder. Turning the toggle off removes app-owned index entries and text copies; system search propagation may be delayed. The primary local library is retained.

Archiving is recoverable; this app does not permanently delete imported records. Files and model output may contain sensitive information. Application Support remains protected by the user's normal Mac account and disk settings; no additional encryption is advertised.

The UI workflow uses a separate randomly named test store. No real client documents or private signing identifiers are included in this repository.
