Assumption: by “all three” you mean **Mobile Guard App**, **Backend API**, and **Web Dashboard** from `project-requirement.md`.

## 1. Mobile Guard App Gaps
Implemented foundation exists in `lunar_security_guard`, but these requirements are missing or incomplete:

- **Background GPS telemetry is not created.**  
  Scenario: guard checks in, app starts periodic GPS tracking during the active shift, batches points, handles app background/lock screen, and uploads to backend. Current app only captures location during check-in, check-out, SOS, and incident actions.

- **Offline SQLite queue is not created.**  
  Scenario: guard scans QR or submits incident while offline; app stores it locally with retry state, then auto-syncs when network returns. Current app calls APIs directly and shows errors if offline.

- **Mandatory checkpoint patrol schedule is not created.**  
  Scenario: system tells guard “Checkpoint A due in 10 minutes,” warns if missed, and records compliance. Current app can scan/submit a checkpoint, but it does not enforce patrol intervals or required route order.

- **Hourly all-clear visual logs are not created.**  
  Scenario: during an active shift, app prompts hourly for photo + note, uploads it as `visual_log`, and marks the hour complete. Current app only supports incident photo attachment.

- **Full incident metadata automation is partial.**  
  Scenario: incident should auto-fill guard, site, GPS, timestamp, shift/session, and support multiple media items. Current form asks for manual `siteId`, supports one photo, and does not clearly bind incident to the active shift.

- **Low-connectivity mode UI is placeholder only.**  
  Scenario: guard can inspect queued scans/reports and retry failed uploads. Current login screen shows “Queue status (offline)” but it does nothing.

## 2. Backend API Gaps
Backend has a strong base, but these requirement scenarios are not fully created:

- **Production payroll engine is not created.**  
  Scenario: payroll calculates overtime, shift differentials, pension, UK PAYE/NI rules, adjustments, approvals, and finalized pay runs. Current backend has illustrative payroll from closed attendance sessions only, with a warning that deductions must be verified.

- **Valid BACS/CHAPS export and payslip distribution are not created.**  
  Scenario: admin finalizes payroll, exports bank-valid payment files, and sends digital payslips. Current export has a `bacs_stub`, not a real banking file, and no payslip generation/distribution. -> No Banking Integration is Needed.

- **Immutable audit trail is only partial.**  
  Scenario: every shift change, site update, incident report, payroll action, login, and admin operation is logged immutably. Current audit exists, but only selected auth/user actions are clearly written.

- **Media processing pipeline is partial.**  
  Scenario: uploaded photos are compressed, virus-checked, stored securely in object storage/CDN, and access-controlled. Current backend stores uploads locally and registers metadata.

- **Real-time command infrastructure is not created.**  
  Scenario: supervisors see guard positions and SOS updates live via WebSocket/SSE/push. Current backend is request/response REST; dashboard uses refresh-style loading.

- **Geofence support is partial.**  
  Scenario: sites support precise GPS polygons and check-in validates polygon boundaries. Schema has `geofence_polygon`, but current attendance validation appears centered on circular distance/radius.

- **Reporting/analytics is partial.**  
  Scenario: export staffing utilization, payroll variance, patrol compliance in CSV, Excel, and PDF. Current worker exports limited CSV types only.


## 3. Web Dashboard Gaps
The web dashboard has admin/manager pages, but these larger dashboard requirements are missing or partial:

- **Live situational map is partial.**  
  Scenario: map shows every on-duty guard’s live GPS trail, active patrol path, and real-time incident/SOS alerts. Current map shows markers from active shifts, incidents, and SOS; shifts use site center, not live guard location or trails.

- **Drag-and-drop scheduler is not created.**  
  Scenario: supervisor drags shifts on a calendar, creates recurring templates, detects conflicts visually, and edits assignments. Current page has forms/tables for shift creation and editing, not calendar drag/drop.

- **Automated shift swap management is not created in UI.**  
  Scenario: guard requests swap, supervisor sees approval queue, system checks availability/conflicts, then reassigns shift. Backend has some swap endpoints, but the web dashboard does not expose full swap workflow.

- **Employee lifecycle management is partial.**  
  Scenario: HR manages contracts, documents, emergency contacts, employment status, onboarding/offboarding, and archived records. Current web app has user listing/profile basics, not full HR document lifecycle.

- **Compliance/training tracker is partial.**  
  Scenario: dashboard tracks required certifications, expiry alerts, missing training, renewal workflow, and compliance status by guard/site. Current certification page stores records but lacks alerting, required-training rules, and renewal workflow.

- **Payroll UI is partial.**  
  Scenario: admin reviews calculated payroll, resolves exceptions, finalizes run, exports payment files, and distributes payslips. Current page creates/view payroll runs and lines only.

- **Operational KPI tiles are partial.**  
  Scenario: dashboard shows on-duty guards, missed checkpoints, pending incidents, patrol compliance, late check-ins, and exceptions. Current KPI page has active shifts/open incidents/SOS counts; missed checkpoints is backend-estimated as `0`.

- **Site/asset management is partial.**  
  Scenario: admin draws GPS perimeters, manages site assets, generates/prints checkpoint QR codes, and validates checkpoint placement. Current app supports site/checkpoint pages and QR display, but not full perimeter drawing or asset management.

 Biggest missing end-to-end scenarios are: **offline mobile sync**, **background GPS/live guard tracking**, **real drag-and-drop scheduling**, **production payroll/payslips/bank exports**, and **true real-time command center**.