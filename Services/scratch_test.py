import asyncio
import os
import sys

# Add Services directory to path
services_dir = os.path.abspath(os.path.dirname(__file__))
if services_dir not in sys.path:
    sys.path.insert(0, services_dir)

from services import ai_service

sample_doc_text = """APPLICATION FORM
APPLICATION NO: HCLTFP2387025
Personal Details
Name: GODFREY T R
Email ID: godfreytr.prof@gmail.com
Mobile Number: +91-9344462238
Date of Birth: 08/10/2005
Gender: Male
Address For Correspondence:
Country: India
State: Tamil Nadu
District: Tiruchirappalli
City: Tiruchirappalli
Address Line 1: 2/38 B, P.S.NAGAR, AKILANDAPURAM
Address Line 2: THALAKUDI, NO1. TOLLGATE
Pincode: 621216

10th Academic Details:
School Name: SRIBALA VIDYAMANDIR HR SEC SCHOOL
Name of Board: Tamil Nadu Board Of Secondary Education
Year of Passing: 2021
Marking Scheme: Percentage
Obtained Percentage/CGPA: 100
Roll Number: 2534197
What You Opted For After 10th?: 12th

12th Academic Details:
School Name: SRIBALA VIDYAMANDIR HR SEC SCHOOL
Name of Board: Tamil Nadu Board Of Higher Secondary Education
Stream: PCM
Year of Passing: 2023
Marking Scheme: Percentage
Obtained Percentage/CGPA: 79

Under Graduate Details:
State: Tamil Nadu
University: Anna University, Tamilnadu
College: K Ramakrishnan College of Technology, Trichy
Degree Name: BE
Degree Specialization: Computer Science and Engineering
Year of Passing: 2027
Result Status: Pursuing
Marking Scheme: Percentage
Obtained Percentage/CGPA: 72.90
Semester/Trimester: 7

Previous Work Experience Detail:
Have You Previously Worked With HCL?: No
Do You Have Any Work Experience ?: No

Upload File:
Upload Your Recent Passport Size Photograph: Yes
Upload Your Updated Resume: Yes
Select One Government Issued Valid Identity Proof: Driving License
Upload Identity Proof: Yes

Job Roles Detail:
Are You Sure You Want To Apply For Technical Roles: Yes
Technical Specializations: Computer Science

Declaration:
I Certify That The Information Submitted By Me In Support Of This Application, Is True To The Best Of Knowledge And Belief.
Applicant Name: GODFREY T R
Date: 17/09/2026
"""

async def test_all():
    print("--- 1. Testing Text Generation / Ping ---")
    try:
        ping_res = await ai_service.generate_text("Say 'AI Service Active' if you receive this message.")
        print(f"Ping response: {ping_res[:100]}...\n")
    except Exception as e:
        print(f"Ping failed: {e}\n")

    print("--- 2. Testing Summarize PDF / Document ---")
    try:
        sum_res = await ai_service.summarize_pdf(sample_doc_text, mode="detailed", language="English")
        print(f"Summary result:\n{sum_res}\n")
    except Exception as e:
        print(f"Summarize failed: {e}\n")

    print("--- 3. Testing Parse CV ---")
    try:
        cv_res = await ai_service.parse_cv(sample_doc_text)
        print(f"Parse CV result:\n{cv_res}\n")
    except Exception as e:
        print(f"Parse CV failed: {e}\n")

    print("--- 4. Testing Extract Information ---")
    try:
        info_res = await ai_service.extract_information(sample_doc_text)
        print(f"Extract Info result:\n{info_res}\n")
    except Exception as e:
        print(f"Extract Info failed: {e}\n")

    print("--- 5. Testing Classify Document ---")
    try:
        class_res = await ai_service.classify_document(sample_doc_text)
        print(f"Classify Document result:\n{class_res}\n")
    except Exception as e:
        print(f"Classify Document failed: {e}\n")

    print("--- 6. Testing Detect Privacy / PII ---")
    try:
        priv_res = await ai_service.detect_privacy_and_pii(sample_doc_text)
        print(f"Detect Privacy result:\n{priv_res}\n")
    except Exception as e:
        print(f"Detect Privacy failed: {e}\n")

    print("--- 7. Testing Ask PDF ---")
    try:
        ask_res = await ai_service.ask_pdf(sample_doc_text, "What is the candidate's degree and percentage?")
        print(f"Ask PDF result:\n{ask_res}\n")
    except Exception as e:
        print(f"Ask PDF failed: {e}\n")

    print("--- 8. Testing Quality Check ---")
    try:
        qual_res = await ai_service.quality_check_document(sample_doc_text)
        print(f"Quality Check result:\n{qual_res}\n")
    except Exception as e:
        print(f"Quality Check failed: {e}\n")

if __name__ == "__main__":
    asyncio.run(test_all())
