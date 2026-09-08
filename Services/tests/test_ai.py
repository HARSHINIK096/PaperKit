"""AI Services and Document Intelligence Test Suite"""
import pytest
from unittest.mock import patch, AsyncMock
from services import ai_service


@pytest.mark.asyncio
async def test_summarize_pdf(client, seeded_file, auth_headers):
    """POST /ai/summarize returns AI summary."""
    mock_summary = "This is a concise summary of the PaperKit document."
    with patch.object(ai_service, "summarize_pdf", new=AsyncMock(return_value=mock_summary)):
        file_id = str(seeded_file["_id"])
        resp = await client.post(
            "/ai/summarize",
            json={"file_id": file_id, "mode": "short", "language": "English"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "summary" in data
        assert data["summary"] == mock_summary


@pytest.mark.asyncio
async def test_ask_pdf_question(client, seeded_file, auth_headers):
    """POST /ai/ask answers user query based on PDF context."""
    mock_answer = "PaperKit is an open-source document platform."
    with patch.object(ai_service, "ask_pdf", new=AsyncMock(return_value=mock_answer)):
        file_id = str(seeded_file["_id"])
        resp = await client.post(
            "/ai/ask",
            json={"file_id": file_id, "question": "What is PaperKit?"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["answer"] == mock_answer


@pytest.mark.asyncio
async def test_ocr_extract(client, seeded_file, auth_headers):
    """POST /ai/ocr extracts text content with AI vision OCR."""
    mock_ocr = "PaperKit OCR Extracted Text"
    with patch.object(ai_service, "ocr_pdf", new=AsyncMock(return_value=mock_ocr)):
        file_id = str(seeded_file["_id"])
        resp = await client.post(
            "/ai/ocr",
            json={"file_id": file_id},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["text"] == mock_ocr


@pytest.mark.asyncio
async def test_compare_documents(client, auth_headers):
    """POST /ai/compare performs semantic comparison between texts."""
    mock_comp = {"similarity_score": 88, "changes": []}
    with patch.object(ai_service, "compare_documents", new=AsyncMock(return_value=mock_comp)):
        resp = await client.post(
            "/ai/compare",
            json={"text_a": "First document content", "text_b": "Second document content"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["similarity_score"] == 88


@pytest.mark.asyncio
async def test_semantic_search(client, auth_headers):
    """POST /ai/search performs semantic search inside document text."""
    mock_results = {"query": "Universal Test", "results": [{"chunk": "PaperKit Universal Test Document", "score": 0.95}]}
    with patch.object(ai_service, "semantic_search", new=AsyncMock(return_value=mock_results)):
        resp = await client.post(
            "/ai/search",
            json={"text": "Sample text for search", "query": "Universal Test"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert "results" in resp.json()


@pytest.mark.asyncio
async def test_translate_document(client, auth_headers):
    """POST /ai/translate translates text to target language."""
    mock_translation = "Documento de prueba universal PaperKit"
    with patch.object(ai_service, "translate_pdf", new=AsyncMock(return_value=mock_translation)):
        resp = await client.post(
            "/ai/translate",
            json={"text": "PaperKit Universal Test Document", "target_language": "Spanish"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["translation"] == mock_translation


@pytest.mark.asyncio
async def test_writing_assistant(client, auth_headers):
    """POST /ai/writing-assist assists with style, grammar and enhancement."""
    mock_res = {"improved_text": "Polished text output", "improvements": ["fixed grammar"]}
    with patch.object(ai_service, "writing_assistant", new=AsyncMock(return_value=mock_res)):
        resp = await client.post(
            "/ai/writing-assist",
            json={"text": "raw draft", "task": "grammar_spelling"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["improved_text"] == "Polished text output"


@pytest.mark.asyncio
async def test_classify_document(client, auth_headers):
    """POST /ai/classify categorizes document type."""
    mock_classification = {"category": "Research Paper", "confidence": 94}
    with patch.object(ai_service, "classify_document", new=AsyncMock(return_value=mock_classification)):
        resp = await client.post(
            "/ai/classify",
            json={"text": "Technical Report: Architecture of PaperKit"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["category"] == "Research Paper"


@pytest.mark.asyncio
async def test_detect_privacy(client, auth_headers):
    """POST /ai/detect-privacy scans for PII and sensitive data."""
    mock_privacy = {"total_found": 0, "risk_level": "LOW", "entities": []}
    with patch.object(ai_service, "detect_privacy_and_pii", new=AsyncMock(return_value=mock_privacy)):
        resp = await client.post(
            "/ai/detect-privacy",
            json={"text": "Normal document with no PII."},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["risk_level"] == "LOW"


@pytest.mark.asyncio
async def test_quality_check(client, auth_headers):
    """POST /ai/quality-check audits document structure and readability."""
    mock_quality = {"overall_score": 90, "items": []}
    with patch.object(ai_service, "quality_check_document", new=AsyncMock(return_value=mock_quality)):
        resp = await client.post(
            "/ai/quality-check",
            json={"text": "Quality audit document text."},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["overall_score"] == 90
