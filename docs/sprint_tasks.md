Sprint 1 – Project Setup & Document Ingestion

Goal: Upload documents, OCR text extraction, basic request tracking.


Tickets

**Setup & Infrastructure**
1. 		Initialize Rails 7 app (API + Hotwire/Turbo frontend). DONE
2. 		Configure Postgres DB, Active Storage (S3 for pilot). DONE
3. 		Add Devise for authentication (Admin/Staff roles). DONE
4. 		Add Sidekiq + Redis for background job processing. NEW
5. 		Configure error handling & logging (Rails logger + Sidekiq monitoring). NEW

**Core Models**
6. 		Scaffold FoiaRequest model with full schema:
		- request_number (string, unique, auto-generated)
		- requester_name, requester_email, requester_organization (strings)
		- subject, description (text)
		- received_at (datetime, defaults to creation time)
		- due_on (datetime, calculated as received_at + 5 business days)
		- status (enum: pending, in_progress, completed, cancelled)
		- user_id (belongs_to :user - assigned staff member)
		- timestamps
7. 		Update Document model:
		- Add foia_request_id (belongs_to :foia_request)
		- Add page_texts (jsonb) for per-page text storage
		- Add processing_status (enum: pending, processing, completed, failed)
		- Add file_type, file_size_bytes, page_count (metadata)
		- Keep existing: title, extracted_text (for full text search)
		- belongs_to :user (uploader)

**Document Upload & Processing**
8. 		Implement file upload (PDF/DOCX/TXT) via Active Storage. DONE
9. 		Add batch document upload (multiple files to one request). NEW
		- Accept multiple files in upload form
		- Associate all with single FoiaRequest
		- Queue background jobs for each file
10. 	Update DocumentTextExtractionService:
		- Extract text per page into page_texts JSONB: {"1": "text...", "2": "text..."}
		- Store total page count
		- Store file metadata (type, size)
		- Update processing_status
11. 	Create ExtractDocumentTextJob (Sidekiq):
		- Call DocumentTextExtractionService
		- Handle errors and retry logic (3 attempts)
		- Update document processing_status
12. 	Integrate Tesseract OCR for scanned PDFs:
		- Detect if PDF has text layer (no extractable text)
		- If scanned, use Tesseract OCR (rtesseract gem)
		- Store OCR'd text in page_texts
		- Add ticket for optional AWS Textract integration later

**Dashboard & Views**
13. 	Create FOIA Requests dashboard (index):
		- List all requests with filters (status, date range)
		- Show: request_number, requester_name, subject, due_on, status
		- Color-coded deadline indicators (overdue, due soon, on track)
		- Pagination (20 per page)
14. 	Create FOIA Request detail view:
		- Show request info (requester, subject, dates, status)
		- List all associated documents with thumbnails
		- Show per-document processing status
		- Upload additional documents to request
15. 	Update document display in request detail:
		- Show file type icons (PDF/DOCX/TXT)
		- Display processing status with progress indicators
		- File size and page count
		- Download original file link
* 		Highlight detected matches in document viewer (Turbo stream updates).
* 		Implement redaction service:
* 		
    * 		Remove text from PDF
    * 		Replace with black box or delete chars
* 		Add verification pass (search redacted file for removed strings).
* 		Generate Redaction Log (CSV + JSON).
* 		Attach redacted PDF + log back to document.



￼
 Sprint 3 – Custom Rules & Summarization (AI API)

Goal: Let users define new rules + add summaries via AI API.


Tickets

* 		Scaffold RedactionRule model (name, type: regex|keywords, pattern/keywords).
* 		UI: Add/Edit/Delete rules in dashboard (Turbo Frames).
* 		Apply custom rules on documents and update Redaction Log.
* 		AI Summarization service:
* 		
    * 		Adapter for OpenAI API
    * 		Generate 200–300 word summaries
    * 		Save Summary model per document/request
* 		Display summaries in request detail view.



￼
 Sprint 4 – FOIA Dashboard, Deadlines & Security Hardening

Goal: Complete pilot dashboard and polish for demo.


Tickets

* 		Extend request dashboard:
* 		
    * 		Status (In Progress/Complete)
    * 		Deadline countdown (business days, skip weekends/holidays)
    * 		Progress indicator (% docs processed)
* 		Export reports (CSV/PDF) with request summary + logs.
* 		Add AuditLog model (who did what, when).
* 		Secure file access (presigned URLs, time-limited).
* 		Basic role-based access: Admin vs Staff.
* 		Deploy to AWS (Rails app + Postgres + S3).
* 		UAT: seed demo data, test with 3–5 users.