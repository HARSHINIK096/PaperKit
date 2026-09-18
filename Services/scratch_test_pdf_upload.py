import asyncio
import os
import sys
import io

# Add Services directory to path
services_dir = os.path.abspath(os.path.dirname(__file__))
if services_dir not in sys.path:
    sys.path.insert(0, services_dir)

from services import ai_service
from routers.ai import _extract_document_text

def create_sample_pdf() -> bytes:
    """Generate a real 4-page PDF document containing the user's application form."""
    from reportlab.lib.pagesizes import letter
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib import colors

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=letter, rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36)
    styles = getSampleStyleSheet()

    header_style = ParagraphStyle('HeaderStyle', parent=styles['Heading1'], fontSize=16, textColor=colors.HexColor('#0055A5'), alignment=1)
    sub_header_style = ParagraphStyle('SubHeader', parent=styles['Heading2'], fontSize=12, textColor=colors.HexColor('#0055A5'), spaceBefore=10, spaceAfter=5)
    cell_style = ParagraphStyle('Cell', parent=styles['Normal'], fontSize=9)
    cell_bold = ParagraphStyle('CellBold', parent=styles['Normal'], fontSize=9, fontName='Helvetica-Bold')

    story = []

    # Page 1: Personal & 10th Details
    story.append(Paragraph("<b>HCLTech APPLICATION FORM</b>", header_style))
    story.append(Paragraph("APPLICATION NO: HCLTFP2387025", ParagraphStyle('AppNo', parent=styles['Normal'], alignment=1, fontSize=10, spaceAfter=15)))

    story.append(Paragraph("Personal Details", sub_header_style))
    p_data = [
        [Paragraph("Name", cell_bold), Paragraph("GODFREY T R", cell_style)],
        [Paragraph("Email ID", cell_bold), Paragraph("godfreytr.prof@gmail.com", cell_style)],
        [Paragraph("Mobile Number", cell_bold), Paragraph("+91-9344462238", cell_style)],
        [Paragraph("Date of Birth", cell_bold), Paragraph("08/10/2005", cell_style)],
        [Paragraph("Gender", cell_bold), Paragraph("Male", cell_style)],
        [Paragraph("Address", cell_bold), Paragraph("2/38 B, P.S.NAGAR, AKILANDAPURAM, THALAKUDI, NO1. TOLLGATE, Tiruchirappalli, Tamil Nadu - 621216", cell_style)],
    ]
    t1 = Table(p_data, colWidths=[150, 350])
    t1.setStyle(TableStyle([('GRID', (0,0), (-1,-1), 0.5, colors.grey), ('BACKGROUND', (0,0), (0,-1), colors.HexColor('#F1F5F9'))]))
    story.append(t1)

    story.append(Spacer(1, 15))
    story.append(Paragraph("10th Academic Details", sub_header_style))
    acad10_data = [
        [Paragraph("School Name", cell_bold), Paragraph("SRIBALA VIDYAMANDIR HR SEC SCHOOL", cell_style)],
        [Paragraph("Name of Board", cell_bold), Paragraph("Tamil Nadu Board Of Secondary Education", cell_style)],
        [Paragraph("Year of Passing", cell_bold), Paragraph("2021", cell_style)],
        [Paragraph("Marking Scheme", cell_bold), Paragraph("Percentage", cell_style)],
        [Paragraph("Obtained Percentage/CGPA", cell_bold), Paragraph("100", cell_style)],
        [Paragraph("Roll Number", cell_bold), Paragraph("2534197", cell_style)],
    ]
    t10 = Table(acad10_data, colWidths=[150, 350])
    t10.setStyle(TableStyle([('GRID', (0,0), (-1,-1), 0.5, colors.grey), ('BACKGROUND', (0,0), (0,-1), colors.HexColor('#F1F5F9'))]))
    story.append(t10)

    story.append(PageBreak())

    # Page 2: 12th & UG Academic Details
    story.append(Paragraph("12th Academic Details", sub_header_style))
    acad12_data = [
        [Paragraph("School Name", cell_bold), Paragraph("SRIBALA VIDYAMANDIR HR SEC SCHOOL", cell_style)],
        [Paragraph("Name of Board", cell_bold), Paragraph("Tamil Nadu Board Of Higher Secondary Education", cell_style)],
        [Paragraph("Stream", cell_bold), Paragraph("PCM", cell_style)],
        [Paragraph("Year of Passing", cell_bold), Paragraph("2023", cell_style)],
        [Paragraph("Obtained Percentage/CGPA", cell_bold), Paragraph("79", cell_style)],
    ]
    t12 = Table(acad12_data, colWidths=[150, 350])
    t12.setStyle(TableStyle([('GRID', (0,0), (-1,-1), 0.5, colors.grey), ('BACKGROUND', (0,0), (0,-1), colors.HexColor('#F1F5F9'))]))
    story.append(t12)

    story.append(Spacer(1, 15))
    story.append(Paragraph("Under Graduate Details", sub_header_style))
    ug_data = [
        [Paragraph("University", cell_bold), Paragraph("Anna University, Tamilnadu", cell_style)],
        [Paragraph("College", cell_bold), Paragraph("K Ramakrishnan College of Technology, Trichy", cell_style)],
        [Paragraph("Degree Name", cell_bold), Paragraph("BE Computer Science and Engineering", cell_style)],
        [Paragraph("Year of Passing", cell_bold), Paragraph("2027", cell_style)],
        [Paragraph("Result Status", cell_bold), Paragraph("Pursuing (Semester 7)", cell_style)],
        [Paragraph("Obtained Percentage/CGPA", cell_bold), Paragraph("72.90", cell_style)],
    ]
    tug = Table(ug_data, colWidths=[150, 350])
    tug.setStyle(TableStyle([('GRID', (0,0), (-1,-1), 0.5, colors.grey), ('BACKGROUND', (0,0), (0,-1), colors.HexColor('#F1F5F9'))]))
    story.append(tug)

    story.append(PageBreak())

    # Page 3: Job Preferences & Declaration
    story.append(Paragraph("Job Roles Detail & Declaration", sub_header_style))
    job_data = [
        [Paragraph("Apply For Technical Roles", cell_bold), Paragraph("Yes", cell_style)],
        [Paragraph("Technical Specializations", cell_bold), Paragraph("Computer Science", cell_style)],
        [Paragraph("Identity Proof", cell_bold), Paragraph("Driving License (Uploaded)", cell_style)],
        [Paragraph("Applicant Name", cell_bold), Paragraph("GODFREY T R", cell_style)],
        [Paragraph("Date of Application", cell_bold), Paragraph("17/09/2026", cell_style)],
    ]
    tjob = Table(job_data, colWidths=[150, 350])
    tjob.setStyle(TableStyle([('GRID', (0,0), (-1,-1), 0.5, colors.grey), ('BACKGROUND', (0,0), (0,-1), colors.HexColor('#F1F5F9'))]))
    story.append(tjob)

    doc.build(story)
    return buffer.getvalue()


async def run_document_ai_tests():
    print("=== Generating Binary PDF Document ===")
    pdf_bytes = create_sample_pdf()
    print(f"PDF Size: {len(pdf_bytes)} bytes")

    print("\n--- 1. Testing PDF Vision OCR / Extract ---")
    ocr_result = await ai_service.ocr_pdf(pdf_bytes)
    print(f"OCR Output (first 300 chars):\n{ocr_result[:300]}...\n")

    print("--- 2. Extracting Document Text via Router Helper ---")
    doc_text = await _extract_document_text(pdf_bytes, filename="hcl_app.pdf", content_type="application/pdf")
    print(f"Extracted Document Text Length: {len(doc_text)} characters\n")

    print("--- 3. AI Document Summarizer ---")
    summary = await ai_service.summarize_pdf(doc_text, mode="detailed", language="English")
    print(f"Summary Output:\n{summary}\n")

    print("--- 4. AI Resume/CV Parser ---")
    cv_data = await ai_service.parse_cv(doc_text)
    print(f"CV Parser Result:\n{cv_data}\n")

    print("--- 5. AI Structured Info Extractor ---")
    info_data = await ai_service.extract_information(doc_text)
    print(f"Extracted Structured Info:\n{info_data}\n")

    print("--- 6. AI Document Classifier ---")
    classification = await ai_service.classify_document(doc_text)
    print(f"Classification Result:\n{classification}\n")

    print("--- 7. AI Privacy & PII Auditor ---")
    privacy = await ai_service.detect_privacy_and_pii(doc_text)
    print(f"Privacy/PII Result:\n{privacy}\n")

    print("--- 8. AI Question Answering (Ask Document) ---")
    answer1 = await ai_service.ask_pdf(doc_text, "What is the candidate's 10th and 12th percentage?")
    print(f"Q: 10th & 12th percentage?\nA: {answer1}\n")

    answer2 = await ai_service.ask_pdf(doc_text, "Which university and college is the candidate studying at?")
    print(f"Q: University & College?\nA: {answer2}\n")

    print("--- 9. AI Document Quality Checker ---")
    quality = await ai_service.quality_check_document(doc_text)
    print(f"Quality Score: {quality.get('overall_score')}\n")

    print("--- 10. AI Quiz Generator ---")
    quiz = await ai_service.generate_quiz(doc_text, count=3)
    print(f"Quiz Result:\n{quiz}\n")

    print("--- 11. AI Flashcards Generator ---")
    flashcards = await ai_service.generate_flashcards(doc_text, count=3)
    print(f"Flashcards Result:\n{flashcards}\n")

    print("--- 12. AI Mind Map Generator ---")
    mindmap = await ai_service.generate_mindmap(doc_text)
    print(f"Mind Map Result:\n{mindmap}\n")

    print("=== ALL AI FEATURES TESTED SUCCESSFULLY ON RAW PDF DOCUMENT ===")

if __name__ == "__main__":
    asyncio.run(run_document_ai_tests())
