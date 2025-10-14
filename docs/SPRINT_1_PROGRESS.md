# Sprint 1 Progress Report

## ✅ Completed Tasks

### 1. Core Models Created

#### **FoiaRequest Model**
**File:** `app/models/foia_request.rb`

**Features:**
- ✅ Auto-generated request numbers (format: `FOIA-YYYYMMDD-0001`)
- ✅ Status enum: `pending`, `in_progress`, `completed`, `cancelled`
- ✅ Automatic due date calculation (5 business days from received_at)
- ✅ Business days countdown (excludes weekends)
- ✅ Processing progress tracking (% of documents completed)
- ✅ Associations: `belongs_to :user`, `has_many :documents`

**Database Fields:**
- `request_number` (string, unique)
- `requester_name`, `requester_email`, `requester_organization` (strings)
- `subject` (string), `description` (text)
- `received_at` (datetime, auto-set on creation)
- `due_on` (datetime, auto-calculated)
- `status` (integer enum)
- `user_id` (references users table)

**Key Methods:**
- `days_until_due` - Calculates business days remaining
- `overdue?` - Checks if request is past due date
- `processing_progress` - Returns % of documents processed
- Scopes: `overdue`, `due_soon`, `active`

---

#### **Updated Document Model**
**File:** `app/models/document.rb`

**New Features:**
- ✅ FOIA request association (`belongs_to :foia_request, optional: true`)
- ✅ Per-page text storage (`page_texts` JSONB column)
- ✅ Processing status enum: `pending`, `processing`, `completed`, `failed`
- ✅ File metadata tracking (type, size, page count)
- ✅ Support for TXT files in addition to PDF/DOCX
- ✅ Automatic file metadata extraction on save

**New Database Fields:**
- `foia_request_id` (references foia_requests table, optional)
- `page_texts` (jsonb, stores text per page: `{"1": "text...", "2": "text..."}`)
- `processing_status` (integer enum, default: 0/pending)
- `file_type` (string, MIME type)
- `file_size_bytes` (bigint)
- `page_count` (integer, default: 0)

**New Methods:**
- `get_page_text(page_number)` - Retrieve text from specific page
- `total_pages` - Get page count
- `file_extension` - Get file extension (.pdf, .docx, .txt)
- `file_icon_class` - Get Tailwind CSS class for file icon color
- `formatted_file_size` - Human-readable file size (KB/MB)

**Scopes:**
- `by_foia_request(request_id)` - Filter by FOIA request
- `processed` - Only completed documents
- `unprocessed` - Documents not yet completed

---

### 2. Enhanced Text Extraction Service

**File:** `app/services/document_text_extraction_service.rb`

**Updates:**
- ✅ Returns structured data: `{ page_texts: {...}, page_count: N }`
- ✅ Updates document `processing_status` during extraction
- ✅ Stores text per page in `page_texts` JSONB column
- ✅ Stores combined text in `extracted_text` for full-text search
- ✅ Tracks page count and file metadata
- ✅ Added support for TXT files
- ✅ Enhanced error handling with status updates

**PDF Extraction:**
- Processes up to 100 pages
- Stores each page separately in JSONB
- Handles extraction errors per page gracefully

**DOCX Extraction:**
- Treats entire document as page "1"
- Joins all paragraphs with double line breaks

**TXT Extraction:**
- Simple UTF-8 text extraction
- Stored as page "1"

---

## 📊 Database Schema Changes

### New Tables:
1. **foia_requests**
   - Primary key: `id`
   - Unique index on `request_number`
   - Foreign key to `users` table

### Modified Tables:
1. **documents**
   - Added `foia_request_id` (foreign key, optional)
   - Added `page_texts` (jsonb, default: {})
   - Added `processing_status` (integer, default: 0)
   - Added `file_type` (string)
   - Added `file_size_bytes` (bigint)
   - Added `page_count` (integer, default: 0)
   - Index on `processing_status`
   - Index on `foia_request_id`

---

## 🎯 What This Enables

### 1. **Multi-Document FOIA Requests**
- Users can now create a FOIA request
- Upload multiple documents to a single request
- Track overall request status

### 2. **Page-Level Text Storage**
- Enables page-specific redaction in Sprint 2
- Example: "Redact SSN on page 3, lines 12-15"
- Supports document viewer with highlighting

### 3. **Processing Status Tracking**
- Real-time status updates: pending → processing → completed
- Error handling: documents marked as "failed"
- Dashboard can show processing progress per request

### 4. **Business Days Calculation**
- Accurate deadline tracking (excludes weekends)
- Overdue detection
- Due soon alerts (within 2 days)

### 5. **File Metadata**
- Human-readable file sizes
- Page count display
- File type icons with proper coloring

---

## 🚀 Next Steps for Sprint 1

### Remaining Tickets:

**4. ⏳ Add Sidekiq + Redis for background job processing**
- Install gems: `sidekiq`, `redis`
- Configure Redis connection
- Create `ExtractDocumentTextJob` Sidekiq worker
- Update upload controller to queue jobs asynchronously

**5. ⏳ Configure error handling & logging**
- Sidekiq monitoring dashboard
- Error notifications (email/Slack)
- Structured logging with request IDs

**9. ⏳ Add batch document upload**
- Update upload form to accept multiple files
- Create/select FOIA request during upload
- Queue extraction job for each document

**12. ⏳ Integrate Tesseract OCR for scanned PDFs**
- Install Tesseract system dependency
- Detect if PDF is scanned (no text layer)
- Fall back to OCR if needed
- Store OCR'd text in `page_texts`

**13-15. ⏳ Create FOIA Request Dashboard & Views**
- **Index page**: List all requests with filters
- **Detail page**: Show request info + documents list
- **Forms**: Create/edit FOIA requests
- **Upload interface**: Batch document upload to request

---

## 📝 Testing Recommendations

### Model Testing:
```ruby
# Test FoiaRequest
- Auto-generation of request numbers
- Due date calculation (5 business days)
- Business days countdown
- Processing progress calculation
- Status transitions

# Test Document
- FOIA request association
- Processing status enum
- File metadata extraction
- Page text retrieval
```

### Service Testing:
```ruby
# Test DocumentTextExtractionService
- PDF extraction (multi-page)
- DOCX extraction (as single page)
- TXT extraction
- Error handling
- Status updates
- Page count tracking
```

### Integration Testing:
```ruby
# Test upload flow
- Upload document with FOIA request
- Verify processing status updates
- Verify page_texts JSONB structure
- Verify file metadata saved
```

---

## 🎯 Success Metrics

- ✅ FoiaRequest model with all required fields
- ✅ Document model updated with FOIA integration
- ✅ Per-page text extraction working
- ✅ Processing status tracking implemented
- ✅ Migrations ran successfully
- ✅ All models have proper validations and associations

**Next:** Create controllers and views for FOIA request management!
