"""AI Services and Document Intelligence Test Suite"""
import pytest
from unittest.mock import patch, AsyncMock
from services import ai_service


@pytest.mark.asyncio
async def test_summarize_pdf(client, seeded_file, auth_headers):
    """POST /ai/summarize returns AI summary."""
    mock_summary = "This is a concise summary of the MaskerV document."
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
    mock_answer = "MaskerV is an open-source document platform."
    with patch.object(ai_service, "ask_pdf", new=AsyncMock(return_value=mock_answer)):
        file_id = str(seeded_file["_id"])
        resp = await client.post(
            "/ai/ask",
            json={"file_id": file_id, "question": "What is MaskerV?"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["answer"] == mock_answer


@pytest.mark.asyncio
async def test_ocr_extract(client, seeded_file, auth_headers):
    """POST /ai/ocr extracts text content with AI vision OCR."""
    mock_ocr = "MaskerV OCR Extracted Text"
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
    mock_results = {"query": "Universal Test", "results": [{"chunk": "MaskerV Universal Test Document", "score": 0.95}]}
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
    mock_translation = "Documento de prueba universal MaskerV"
    with patch.object(ai_service, "translate_pdf", new=AsyncMock(return_value=mock_translation)):
        resp = await client.post(
            "/ai/translate",
            json={"text": "MaskerV Universal Test Document", "target_language": "Spanish"},
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
            json={"text": "Technical Report: Architecture of MaskerV"},
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


@pytest.mark.asyncio
async def test_generate_podcast_script(client, auth_headers):
    """POST /ai/podcast-script generates multi-speaker dialogue."""
    mock_script = {
        "title": "Test Podcast",
        "summary": "Summary",
        "dialogue": [{"speaker": "Alex (Host)", "text": "Hello", "timestamp": "00:00"}],
    }
    with patch.object(ai_service, "generate_podcast_script", new=AsyncMock(return_value=mock_script)):
        resp = await client.post(
            "/ai/podcast-script",
            json={"text": "Sample document text for podcast generation."},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["title"] == "Test Podcast"
        assert len(resp.json()["dialogue"]) == 1


@pytest.mark.asyncio
async def test_analyze_research_paper(client, seeded_file, auth_headers):
    """POST /ai/analyze-research performs structural academic research analysis."""
    mock_analysis = {
        "title": "A Novel Deep Learning Approach",
        "authors": ["Dr. Jane Doe"],
        "abstract": "We present a novel approach.",
        "methodology": "Neural network architecture.",
        "results": "Accuracy improved by 15%.",
        "limitations": ["Limited dataset size"],
        "future_work": ["Scale up parameters"],
        "sections": [],
    }
    with patch.object(ai_service, "analyze_research_paper", new=AsyncMock(return_value=mock_analysis)):
        file_id = str(seeded_file["_id"])
        resp = await client.post(
            "/ai/analyze-research",
            json={"file_id": file_id},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["title"] == "A Novel Deep Learning Approach"
        assert len(data["authors"]) == 1


@pytest.mark.asyncio
async def test_literature_review(client, seeded_file, auth_headers):
    """POST /ai/literature-review synthesizes multiple documents."""
    mock_review = {
        "overview": "Overview of literature.",
        "research_themes": [],
        "methodology_comparison": [],
        "synthesis": "Comprehensive synthesis.",
    }
    with patch.object(ai_service, "literature_review", new=AsyncMock(return_value=mock_review)):
        file_id = str(seeded_file["_id"])
        resp = await client.post(
            "/ai/literature-review",
            json={"file_ids": [file_id]},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["overview"] == "Overview of literature."


@pytest.mark.asyncio
async def test_speech_to_text(client, auth_headers):
    """POST /ai/speech-to-text transcribes audio."""
    with patch.object(ai_service, "transcribe_audio", new=AsyncMock(return_value="Transcribed test audio")):
        files = {"file": ("test.wav", b"RIFF....WAVEfmt ", "audio/wav")}
        resp = await client.post(
            "/ai/speech-to-text",
            files=files,
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["text"] == "Transcribed test audio"


@pytest.mark.asyncio
async def test_text_to_speech(client, auth_headers):
    """POST /ai/text-to-speech synthesizes speech audio."""
    resp = await client.post(
        "/ai/text-to-speech",
        json={"text": "Hello world from MaskerV AI"},
        headers=auth_headers,
    )
    assert resp.status_code == 200


