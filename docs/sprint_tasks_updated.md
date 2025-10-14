# Sprint Tasks - FOIA AI Assistant

## Sprint 1 – Project Setup & Document Ingestion

**Goal:** Upload documents, OCR text extraction, basic request tracking.

### Tickets

#### Setup & Infrastructure
1. ✅ Initialize Rails 7 app (API + Hotwire/Turbo frontend). **DONE**
2. ✅ Configure Postgres DB, Active Storage (S3 for pilot). **DONE**
3. ✅ Add Devise for authentication (Admin/Staff roles). **DONE**
4. 🔴 Add Sidekiq + Redis for background job processing. **NEW**
5. 🔴 Configure error handling & logging (Rails logger + Sidekiq monitoring). **NEW**

#### Core Models
6. Scaffold FoiaRequest model with full schema:
   - request_number (string, unique, auto-generated)
   - requester_name, requester_email, requester_organization (strings)
   - subject, description (text)
   - received_at (datetime, defaults to creation time)
   - due_on (datetime, calculated as received_at + 5 business days)
   - status (enum: pending, in_progress, completed, cancelled)
   - user_id (belongs_to :user - assigned staff member)
   - timestamps

7. Update Document model:
   - Add foia_request_id (belongs_to :foia_request)
   - Add page_texts (jsonb) for per-page text storage
   - Add processing_status (enum: pending, processing, completed, failed)
   - Add file_type, file_size_bytes, page_count (metadata)
   - Keep existing: title, extracted_text (for full text search)
   - belongs_to :user (uploader)

#### Document Upload & Processing
8. ✅ Implement file upload (PDF/DOCX/TXT) via Active Storage. **DONE**

9. 🔴 Add batch document upload (multiple files to one request). **NEW**
   - Accept multiple files in upload form
   - Associate all with single FoiaRequest
   - Queue background jobs for each file

10. Update DocumentTextExtractionService:
    - Extract text per page into page_texts JSONB: `{"1": "text...", "2": "text..."}`
    - Store total page count
    - Store file metadata (type, size)
    - Update processing_status

11. Create ExtractDocumentTextJob (Sidekiq):
    - Call DocumentTextExtractionService
    - Handle errors and retry logic (3 attempts)
    - Update document processing_status

12. Integrate Tesseract OCR for scanned PDFs:
    - Detect if PDF has text layer (no extractable text)
    - If scanned, use Tesseract OCR (rtesseract gem)
    - Store OCR'd text in page_texts
    - Add ticket for optional AWS Textract integration later

#### Dashboard & Views
13. Create FOIA Requests dashboard (index):
    - List all requests with filters (status, date range)
    - Show: request_number, requester_name, subject, due_on, status
    - Color-coded deadline indicators (overdue, due soon, on track)
    - Pagination (20 per page)

14. Create FOIA Request detail view:
    - Show request info (requester, subject, dates, status)
    - List all associated documents with thumbnails
    - Show per-document processing status
    - Upload additional documents to request
    - Edit request details

15. Update document display in request detail:
    - Show file type icons (PDF/DOCX/TXT)
    - Display processing status with progress indicators
    - File size and page count
    - Download original file link

---

## Sprint 2 – Automated Redaction (Regex + Pipeline)

**Goal:** Detect & redact sensitive info deterministically.

### Tickets

#### Detection Engine
1. Implement regex-based detectors:
   - SSNs (XXX-XX-XXXX format)
   - Phone numbers (various formats)
   - Email addresses
   - Physical addresses (street, city, state, zip)

2. 🔴 Add FERPA/HIPAA keyword detectors. **NEW**
   - Student ID, grade, GPA, discipline
   - Patient, diagnosis, medical record number
   - Case numbers, badge numbers

3. 🔴 Integrate spaCy for Named Entity Recognition (names). **NEW**
   - Detect PERSON entities
   - OR use OpenAI API for name detection (decision needed)
   - Return confidence scores

#### Finding Storage & Display
4. Build Finding model to store matches:
   - document_id (belongs_to :document)
   - page_number (integer)
   - start_position, end_position (character offsets)
   - label (string: ssn, phone, email, address, name, custom)
   - matched_text (encrypted string for audit)
   - confidence (decimal 0.0-1.0)
   - source (string: regex, nlp, custom_rule)
   - status (enum: pending, approved, rejected, redacted)
   - timestamps

5. 🔴 Build PDF viewer with detection highlights (PDF.js + Turbo). **NEW**
   - Load PDF in browser
   - Overlay highlight boxes on detected findings
   - Color-code by type (red=SSN, yellow=name, etc.)
   - Click to view finding details

6. 🔴 Implement approval workflow for findings. **NEW**
   - Staff reviews highlighted findings before redaction
   - Approve/Reject individual findings
   - Bulk approve all
   - Save approved findings for redaction

#### Redaction Service
7. Implement redaction service:
   - Remove text from PDF using pdf-reader + Prawn
   - Replace with black boxes
   - OR use combinepdf gem for PDF manipulation
   - Process only approved findings

8. Add verification pass:
   - Search redacted file for removed strings
   - Ensure no sensitive data remains
   - Log any verification failures

9. Generate Redaction Log:
   - CSV format with: page, type, original_text_hash, position
   - JSON format for API consumption
   - Include metadata: who, when, rule applied

10. Attach redacted PDF + log back to document:
    - Store as separate Active Storage attachments
    - Link to original document record
    - Update document status to "redacted"

---

## Sprint 3 – Custom Rules & Summarization (AI API)

**Goal:** Let users define new rules + add summaries via AI API.

### Tickets

#### Custom Redaction Rules
1. Scaffold RedactionRule model:
   - name (string, unique)
   - description (text)
   - rule_type (enum: regex, keywords)
   - pattern (string, for regex)
   - keywords (jsonb array, for keyword matching)
   - case_sensitive (boolean)
   - user_id (belongs_to :user - creator)
   - active (boolean)
   - timestamps

2. UI: Add/Edit/Delete rules in dashboard (Turbo Frames):
   - Form with regex tester (live preview)
   - Keyword list builder
   - Test against sample text
   - Enable/disable rules

3. Apply custom rules on documents:
   - Run custom rules after built-in detectors
   - Store findings with source="custom_rule"
   - Update Redaction Log with custom rule names

4. 🔴 Add AI-assisted keyword suggestions for custom rules. **NEW**
   - User provides description: "Budget amounts"
   - AI suggests regex patterns and keywords
   - User reviews and accepts/modifies

#### Summarization
5. AI Summarization service:
   - Adapter for OpenAI API (GPT-4 or GPT-3.5-turbo)
   - Generate 200–300 word summaries
   - Handle long documents (chunking if needed)
   - Error handling and retries

6. Scaffold Summary model:
   - document_id (belongs_to :document) - for document-level
   - foia_request_id (belongs_to :foia_request) - for request-level
   - summary_type (enum: document, request)
   - content (text)
   - word_count (integer)
   - generated_at (datetime)
   - timestamps

7. 🔴 Generate request-level summary (all documents combined). **NEW**
   - Aggregate all document summaries
   - Create meta-summary of entire FOIA request
   - Display on request detail page

8. Display summaries in request detail view:
   - Collapsible summary panel
   - Word count indicator
   - Regenerate button
   - Copy to clipboard

---

## Sprint 4 – FOIA Dashboard, Deadlines & Security Hardening

**Goal:** Complete pilot dashboard and polish for demo.

### Tickets

#### Enhanced Dashboard
1. Extend request dashboard:
   - Status indicators (In Progress/Complete) with badges
   - Deadline countdown (business days, skip weekends/holidays)
   - Progress indicator (% docs processed, % redacted)
   - Sort and filter options
   - Search by request number, requester name

2. Export reports (CSV/PDF) with request summary + logs:
   - Generate PDF report with request details, summaries, redaction logs
   - CSV export for spreadsheet analysis
   - Include all attached documents list
   - Timestamped and watermarked

#### Audit & Security
3. Add AuditLog model:
   - user_id (belongs_to :user)
   - action (string: created, updated, deleted, viewed, exported)
   - resource_type, resource_id (polymorphic)
   - changes (jsonb - before/after state)
   - ip_address (string)
   - timestamps

4. Secure file access:
   - Presigned URLs for S3 downloads (expires in 1 hour)
   - Time-limited access tokens
   - Log all file accesses in AuditLog

5. Basic role-based access control:
   - Admin: Full access, manage users, view all requests
   - Staff: View assigned requests, cannot delete
   - Implement with Pundit gem or CanCanCan

#### Testing & Deployment
6. 🔴 Load testing with 20 concurrent requests. **NEW**
   - Use Apache Bench or k6
   - Test: 20 requests × 5 docs each
   - Monitor Sidekiq queue performance
   - Identify bottlenecks

7. 🔴 Error handling & retry logic for all async jobs. **NEW**
   - Sidekiq retry with exponential backoff
   - Dead letter queue for failed jobs
   - Email notifications for critical failures

8. 🔴 Create user documentation (PDF guide). **NEW**
   - How to create FOIA request
   - Upload documents and batch processing
   - Review and approve redactions
   - Create custom rules
   - Generate reports

9. 🔴 Add notification system (email when request complete). **NEW**
   - ActionMailer setup
   - Email templates
   - Notify requester when processing done
   - Notify staff when new request assigned

10. Deploy to AWS (Rails app + Postgres + S3):
    - EC2 or Elastic Beanstalk for Rails app
    - RDS for Postgres
    - ElastiCache for Redis (Sidekiq)
    - S3 for file storage
    - SSL/TLS certificates

11. UAT: seed demo data, test with 3–5 users:
    - Create sample FOIA requests
    - Upload test documents
    - Test all workflows end-to-end
    - Collect feedback and iterate

---

## Summary of New Tickets Added

### Sprint 1: 5 new tickets
- Sidekiq + Redis setup
- Error handling & logging
- Batch document upload
- Updated text extraction (per-page)
- Enhanced dashboard views

### Sprint 2: 4 new tickets
- FERPA/HIPAA keyword detection
- spaCy/NLP for name detection
- PDF viewer with highlights
- Approval workflow for redactions

### Sprint 3: 2 new tickets
- AI-assisted rule suggestions
- Request-level summaries

### Sprint 4: 4 new tickets
- Load testing
- Enhanced error handling
- User documentation
- Notification system

**Total New Tickets: 15**
