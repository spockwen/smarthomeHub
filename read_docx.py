# -*- coding: utf-8 -*-
from docx import Document
import sys

# Set output encoding
sys.stdout.reconfigure(encoding='utf-8')

doc = Document(r'E:\harmonyos\A9-基于OpenHarmony的家居设备控制系统.docx')
for para in doc.paragraphs:
    text = para.text.strip()
    if text:
        print(text)