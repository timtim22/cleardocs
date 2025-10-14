# OCR (Tesseract) Setup Guide

## Overview

The system now supports **Optical Character Recognition (OCR)** for scanned PDFs. When a PDF page has no text layer (or very little text), the system automatically:
1. Converts the page to an image
2. Runs Tesseract OCR to extract text
3. Stores the OCR'd text for redaction and search

---

## System Requirements

### Required Dependencies

You need to install two system-level dependencies:

#### 1. **Tesseract OCR Engine**
The actual OCR software that reads text from images.

**macOS (using Homebrew):**
```bash
brew install tesseract
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install tesseract-ocr
```

**Windows:**
Download installer from: https://github.com/UB-Mannheim/tesseract/wiki

#### 2. **ImageMagick**
Image processing library needed to convert PDF pages to images.

**macOS:**
```bash
brew install imagemagick
```

**Ubuntu/Debian:**
```bash
sudo apt-get install imagemagick
```

**Windows:**
Download from: https://imagemagick.org/script/download.php

---

## Verification

After installation, verify both are installed:

```bash
# Check Tesseract
tesseract --version
# Should output: tesseract 5.x.x

# Check ImageMagick
convert --version
# Should output: ImageMagick 7.x.x

# Check if ImageMagick can read PDFs (requires Ghostscript)
convert --version | grep -i delegate
# Should include "pdf" in the list
```

### If PDF support is missing:

**macOS:**
```bash
brew install ghostscript
```

**Ubuntu/Debian:**
```bash
sudo apt-get install ghostscript
```

---

## Ruby Gems (Already Added)

These gems are already in your `Gemfile`:
- ✅ `rtesseract` - Ruby wrapper for Tesseract
- ✅ `mini_magick` - Ruby wrapper for ImageMagick

Already installed via: `bundle install`

---

## How It Works

### Detection Logic

The service automatically detects scanned pages:

```ruby
# In DocumentTextExtractionService
page_text = page.text.strip

if page_text.empty? || page_text.length < 50
  # Page appears to be scanned - use OCR
  ocr_text = ocr_pdf_page(temp_file.path, page_num)
end
```

**Threshold:** If a page has less than 50 characters, it's likely scanned.

### OCR Process

For each scanned page:
1. **Extract page as image** (PNG, 300 DPI, grayscale)
2. **Run Tesseract** with English language model
3. **Return extracted text**
4. **Log results** (how many pages used OCR)

### Performance

- **Regular PDF page:** ~0.1 seconds
- **Scanned page (OCR):** ~2-5 seconds per page
- **100-page scanned document:** ~5-8 minutes

For large documents, you'll want to implement Sidekiq background jobs (Sprint 1, Ticket #11).

---

## Testing OCR

### Test with Rails Console

```ruby
# Start Rails console
rails console

# Load your test document
doc = Document.last

# Extract text (will use OCR if needed)
result = DocumentTextExtractionService.extract(doc)

# Check results
puts result[:success]        # => true
puts result[:page_count]     # => 10
puts result[:text_length]    # => character count

# View OCR'd text for a specific page
doc.reload
puts doc.get_page_text(1)
```

### Check Logs for OCR Activity

```bash
# Watch Rails logs
tail -f log/development.log

# Look for these messages:
# "Page 3 appears to be scanned (12 chars), attempting OCR..."
# "OCR successful for page 3: extracted 1543 characters"
# "Extracted 15234 characters from 10 pages (3 pages used OCR)"
```

---

## Creating a Test Scanned PDF

To test OCR, you need a scanned PDF. Here's how to create one:

### Option 1: Use a Scanner
Scan a paper document and save as PDF.

### Option 2: Convert Image to PDF (Simulated Scan)

```ruby
# Create a test script
# File: test_scanned_pdf.rb

require 'prawn'

Prawn::Document.generate("scanned_test.pdf") do |pdf|
  # Add an image to the PDF (no text layer)
  pdf.text "This text will not be in the PDF"
  pdf.image "/path/to/image.png", fit: [500, 700]
end

puts "Created scanned_test.pdf"
```

### Option 3: Use Sample Files

Government agencies often have sample scanned documents:
- https://www.irs.gov/pub/irs-pdf/ (IRS forms, often scanned)
- Local government websites with archived minutes

---

## Troubleshooting

### Error: "Tesseract command not found"

**Solution:** Install Tesseract (see above)

```bash
brew install tesseract  # macOS
```

### Error: "MiniMagick::Invalid"

**Cause:** ImageMagick can't read PDFs

**Solution:** Install Ghostscript

```bash
brew install ghostscript  # macOS
```

### Error: "OCR failed for page X"

**Possible causes:**
1. **Poor image quality** - OCR works best on clean, high-contrast images
2. **Handwritten text** - Tesseract struggles with handwriting
3. **Non-English text** - Default is English only

**Solutions:**
- For handwriting: Use Google Cloud Vision API or AWS Textract instead
- For other languages: Install Tesseract language packs
  ```bash
  # Example: Spanish
  brew install tesseract-lang
  
  # Then update the service:
  ocr = RTesseract.new(image_file.path, lang: 'spa')
  ```

### Low OCR Accuracy (<80%)

**Try these improvements:**

1. **Increase DPI:**
   ```ruby
   image.density '600'  # Higher resolution
   ```

2. **Pre-process image:**
   ```ruby
   image.enhance        # Sharpen
   image.normalize      # Adjust contrast
   ```

3. **Use AWS Textract:**
   - Higher accuracy (90-99%)
   - Handles tables, forms, handwriting
   - Costs ~$1.50 per 1000 pages

---

## Configuration Options

### Adjust OCR Threshold

Default is 50 characters. Adjust in `document_text_extraction_service.rb`:

```ruby
# More aggressive (assume more pages are scanned)
if page_text.empty? || page_text.length < 100

# Less aggressive (only truly empty pages)
if page_text.empty? || page_text.length < 10
```

### Change Language

For non-English documents:

```ruby
# In ocr_pdf_page method:
ocr = RTesseract.new(image_file.path, lang: 'spa')  # Spanish
ocr = RTesseract.new(image_file.path, lang: 'fra')  # French

# Multiple languages:
ocr = RTesseract.new(image_file.path, lang: 'eng+spa')
```

---

## Production Considerations

### 1. Use Background Jobs
OCR is slow - use Sidekiq (Sprint 1, Ticket #11):

```ruby
# In controller:
ExtractDocumentTextJob.perform_later(document)
```

### 2. Cache Results
OCR results are stored in `page_texts` JSONB column - no need to re-run.

### 3. Consider AWS Textract for Production
- Better accuracy
- No server dependencies
- Scalable
- Cost: ~$1.50 per 1000 pages

### 4. Monitor Performance
Add metrics:
```ruby
# How many documents use OCR?
Document.where("page_texts::text LIKE '%OCR%'").count

# Average processing time per document
# (Add instrumentation in service)
```

---

## Next Steps

- ✅ OCR installed and working
- ⏳ **Ticket #11:** Create background job for async processing
- ⏳ **Sprint 2:** Use OCR'd text for redaction detection
- ⏳ **Optional:** Integrate AWS Textract for better accuracy

---

## Resources

- **Tesseract Documentation:** https://tesseract-ocr.github.io/
- **RTesseract Gem:** https://github.com/dannnylo/rtesseract
- **MiniMagick Gem:** https://github.com/minimagick/minimagick
- **ImageMagick Docs:** https://imagemagick.org/
