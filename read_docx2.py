# -*- coding: utf-8 -*-
from docx import Document
import codecs

doc = Document(r'E:\harmonyos\A9-基于OpenHarmony的家居设备控制系统.docx')

with codecs.open(r'E:\harmonyos\SmartHomeAIHub\docx_content_utf8.txt', 'w', encoding='utf-8') as f:
    for para in doc.paragraphs:
        text = para.text.strip()
        if text:
            f.write(text + '\n')

print("Done - content saved to docx_content_utf8.txt")