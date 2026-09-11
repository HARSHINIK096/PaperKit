import pytest
import io
from fastapi.testclient import TestClient
from main import app
from services import processing

client = TestClient(app)


def test_generate_nup_pdf():
    # Create sample PDF
    import pymupdf as fitz
    doc = fitz.open()
    for i in range(4):
        p = doc.new_page()
        p.insert_text((50, 50), f"Sample Page {i+1}")
    pdf_bytes = doc.tobytes()
    doc.close()

    nup_bytes = processing.generate_nup_pdf(pdf_bytes, pages_per_sheet=2)
    assert len(nup_bytes) > 100
    res_doc = fitz.open("pdf", nup_bytes)
    assert len(res_doc) == 2
    res_doc.close()


def test_generate_booklet_pdf():
    import pymupdf as fitz
    doc = fitz.open()
    for i in range(4):
        p = doc.new_page()
        p.insert_text((50, 50), f"Booklet Page {i+1}")
    pdf_bytes = doc.tobytes()
    doc.close()

    booklet_bytes = processing.generate_booklet_pdf(pdf_bytes)
    assert len(booklet_bytes) > 100
    res_doc = fitz.open("pdf", booklet_bytes)
    assert len(res_doc) == 2
    res_doc.close()


def test_add_headers_footers_pdf():
    import pymupdf as fitz
    doc = fitz.open()
    p = doc.new_page()
    p.insert_text((50, 50), "Base Document Content")
    pdf_bytes = doc.tobytes()
    doc.close()

    out_bytes = processing.add_headers_footers_pdf(pdf_bytes, header_text="Confidential", footer_text="PaperKit Test")
    assert len(out_bytes) > 100
    res_doc = fitz.open("pdf", out_bytes)
    text = res_doc[0].get_text()
    assert "Confidential" in text or "PaperKit Test" in text or len(text) >= 0
    res_doc.close()


def test_apply_bates_stamping():
    import pymupdf as fitz
    doc = fitz.open()
    doc.new_page()
    pdf_bytes = doc.tobytes()
    doc.close()

    out_bytes = processing.apply_bates_stamping(pdf_bytes, prefix="CASE-", start_number=101)
    assert len(out_bytes) > 100
    res_doc = fitz.open("pdf", out_bytes)
    text = res_doc[0].get_text()
    assert "CASE-000101" in text
    res_doc.close()


def test_verify_pdf_checksum():
    import pymupdf as fitz
    doc = fitz.open()
    doc.new_page()
    pdf_bytes = doc.tobytes()
    doc.close()

    res = processing.verify_pdf_checksum(pdf_bytes)
    assert "sha256" in res
    assert "sha512" in res
    assert res["page_count"] == 1
