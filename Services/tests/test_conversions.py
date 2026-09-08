"""Document Bidirectional Conversion Test Suite (PDF <-> Word, Excel, PowerPoint, Text, HTML)"""
import pytest
import io
from docx import Document
from openpyxl import Workbook
from pptx import Presentation


@pytest.fixture
def sample_xlsx_bytes():
    """Generates an in-memory XLSX workbook."""
    wb = Workbook()
    ws = wb.active
    ws.title = "PaperKit Sheet"
    ws.append(["ID", "Name", "Score"])
    ws.append([1, "Item A", 95.5])
    ws.append([2, "Item B", 88.0])
    buf = io.BytesIO()
    wb.save(buf)
    return buf.getvalue()


@pytest.fixture
def sample_pptx_bytes():
    """Generates an in-memory PPTX presentation."""
    prs = Presentation()
    slide_layout = prs.slide_layouts[0]
    slide = prs.slides.add_slide(slide_layout)
    title = slide.shapes.title
    subtitle = slide.placeholders[1]
    title.text = "PaperKit Slide"
    subtitle.text = "Conversion testing slide"
    buf = io.BytesIO()
    prs.save(buf)
    return buf.getvalue()


@pytest.mark.asyncio
async def test_convert_pdf_to_word(client, seeded_file, auth_headers):
    """POST /tools/convert converts PDF to Word DOCX."""
    file_id = str(seeded_file["_id"])
    resp = await client.post(
        "/tools/convert",
        json={"file_id": file_id, "from_format": "pdf", "to_format": "word"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "download_url" in data
    assert data["download_url"].endswith(".docx")


@pytest.mark.asyncio
async def test_convert_pdf_to_excel(client, seeded_file, auth_headers):
    """POST /tools/convert converts PDF to Excel XLSX."""
    file_id = str(seeded_file["_id"])
    resp = await client.post(
        "/tools/convert",
        json={"file_id": file_id, "from_format": "pdf", "to_format": "excel"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "download_url" in data
    assert data["download_url"].endswith(".xlsx")


@pytest.mark.asyncio
async def test_convert_pdf_to_ppt(client, seeded_file, auth_headers):
    """POST /tools/convert converts PDF to PPTX."""
    file_id = str(seeded_file["_id"])
    resp = await client.post(
        "/tools/convert",
        json={"file_id": file_id, "from_format": "pdf", "to_format": "ppt"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "download_url" in data
    assert data["download_url"].endswith(".pptx")


@pytest.mark.asyncio
async def test_convert_word_to_pdf(client, sample_docx_bytes, auth_headers):
    """POST /tools/convert converts DOCX to PDF."""
    files = {"file": ("document.docx", sample_docx_bytes, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}
    up_resp = await client.post("/files/upload", files=files, headers=auth_headers)
    file_id = up_resp.json()["_id"]

    resp = await client.post(
        "/tools/convert",
        json={"file_id": file_id, "from_format": "word", "to_format": "pdf"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["download_url"].endswith(".pdf")


@pytest.mark.asyncio
async def test_convert_excel_to_pdf(client, sample_xlsx_bytes, auth_headers):
    """POST /tools/convert converts XLSX to PDF."""
    files = {"file": ("sheet.xlsx", sample_xlsx_bytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")}
    up_resp = await client.post("/files/upload", files=files, headers=auth_headers)
    file_id = up_resp.json()["_id"]

    resp = await client.post(
        "/tools/convert",
        json={"file_id": file_id, "from_format": "excel", "to_format": "pdf"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["download_url"].endswith(".pdf")


@pytest.mark.asyncio
async def test_convert_ppt_to_pdf(client, sample_pptx_bytes, auth_headers):
    """POST /tools/convert converts PPTX to PDF."""
    files = {"file": ("presentation.pptx", sample_pptx_bytes, "application/vnd.openxmlformats-officedocument.presentationml.presentation")}
    up_resp = await client.post("/files/upload", files=files, headers=auth_headers)
    file_id = up_resp.json()["_id"]

    resp = await client.post(
        "/tools/convert",
        json={"file_id": file_id, "from_format": "ppt", "to_format": "pdf"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["download_url"].endswith(".pdf")


@pytest.mark.asyncio
async def test_convert_html_to_word_endpoint(client, auth_headers):
    """POST /tools/html-to-word converts HTML string directly to Word DOCX."""
    resp = await client.post(
        "/tools/html-to-word",
        json={"html_content": "<p>PaperKit Generated Paragraph</p>", "filename": "output.docx"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["download_url"].endswith(".docx")
