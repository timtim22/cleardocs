Scope of Work – FOIA AI Assistant Pilot

🎯 Project Goal

Develop a pilot-ready FOIA AI Assistant that can be demoed with Fairfax County (or another Virginia locality). The system must upload documents, automatically redact sensitive data, generate summaries, and track request deadlines in a simple dashboard.

⸻

📌 Core Features (Pilot Version)

1.⁠ ⁠Document Upload & Processing
	•	Accept PDF, DOCX, TXT files.
	•	OCR for scanned PDFs (basic Tesseract integration).
	•	Batch upload support (multiple files per request).

2.⁠ ⁠Automated Redaction (Core AI Feature)
	•	Detect & redact:
	•	Names
	•	Addresses
	•	Phone numbers
	•	Social Security Numbers
	•	Student/health info (FERPA/HIPAA keywords)
	•	Output: Redacted PDF + Redaction Log (what was removed, where).

3.⁠ ⁠Custom Redaction Rules (New Feature)
	•	Ability for users to add new redaction fields directly from the dashboard.
	•	Options for:
	•	Rule Name (user-defined, e.g., “Case Number”).
	•	Input Type: Regex pattern or Keyword list.
	•	System highlights matches in uploaded documents before redaction.
	•	Redaction log updated to reflect custom rules applied (e.g., “Custom Rule: Case Number – 5 instances redacted”).

4.⁠ ⁠Summarization
	•	Generate plain-language summaries of documents.
	•	Summaries capped at 200–300 words.
	•	Use Hugging Face models or OpenAI API for summarization.

5.⁠ ⁠FOIA Request Dashboard
	•	Track open requests:
	•	Request ID
	•	Upload date
	•	Deadline countdown (default: 5 business days)
	•	Status (In Progress / Complete).
	•	Exportable summary report (PDF/CSV).

6.⁠ ⁠Security (Pilot-Ready)
	•	Simple user login (admin + staff roles).
	•	Basic encryption (SSL/TLS for data in transit).
	•	Local document storage (AWS S3 or Azure Blob).

⸻

📊 Success Criteria (Pilot)
	•	90%+ accuracy in detecting SSNs, addresses, and names in test documents.
	•	Summaries are readable and concise for documents of 10+ pages.
	•	Dashboard can track at least 20 concurrent FOIA requests.
	•	Users can create and apply custom redaction rules successfully.
	•	Pilot deployment is stable and usable by 3–5 test users.

⸻

🛠️ Tech Stack (Recommended)
	•	Frontend: React.js (simple interface).
	•	Backend: Python (FastAPI).
	•	AI Models: spaCy + regex for redaction; Hugging Face / GPT API for summaries.
	•	OCR: Tesseract or AWS Textract.
	•	Database: PostgreSQL or SQLite (pilot version).
	•	Hosting: AWS or Azure (basic cloud deployment for pilot).

⸻

📞 Communication & Reporting
	•	Weekly progress updates via Slack/Zoom.
	•	Bi-weekly demos of working features.
	•	GitHub repo access for code review







    Sample FOIA Document (Mock)

Document Title: Fairfax County School Board Meeting Notes – March 2024

Content:

Attendees:
	•	John Smith, Principal, Westfield High School
	•	Mary Johnson, Parent Advocate, Springfield District
	•	Student ID: 20457891 – related to disciplinary action
	•	Phone: (703) 555-1289
	•	Address: 1234 Maple Lane, Fairfax, VA 22031
	•	Social Security Number: 123-45-6789

Discussion Points:
	1.	School budget allocations for special education ($1.2M for FY24).
	2.	Security camera upgrades in elementary schools.
	3.	Parent complaints regarding after-school program cancellations.
	4.	Proposal to extend language programs to include Arabic and Korean.

Notes: Student records discussed are confidential under FERPA and must be redacted before release.

⸻

🔑 How Dev Team Should Use This Sample
	•	Redaction Tests:
	•	SSN (123-45-6789) → fully redacted.
	•	Phone ((703) 555-1289) → redacted.
	•	Address (1234 Maple Lane...) → redacted.
	•	Student ID (20457891) → redacted.
	•	Names (John Smith, Mary Johnson) → redacted (depending on rule set).
	•	Custom Rule Test:
	•	Add “Budget Amounts” as a custom redaction rule → $1.2M should be redacted.
	•	Summarization Test:
	•	AI should generate something like:
“This document summarizes a Fairfax County School Board meeting on special education funding, security upgrades, after-school program complaints, and expansion of language programs. Sensitive student and personal data have been redacted.”
	•	Dashboard Test:
	•	Upload should create a new FOIA request entry with a 5-day countdown.
	•	Status should change from In Progress → Complete once redaction and summary are finalized.