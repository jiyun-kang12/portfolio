#!/bin/bash

# PDF 파일 압축 스크립트
# Ghostscript가 설치되어 있어야 합니다: brew install ghostscript

cd "$(dirname "$0")/img"

for file in *.pdf; do
  if [ -f "$file" ]; then
    echo "압축 중: $file"
    gs -sDEVICE=pdfwrite \
       -dCompatibilityLevel=1.4 \
       -dPDFSETTINGS=/ebook \
       -dNOPAUSE \
       -dBATCH \
       -sOutputFile="${file%.pdf}_min.pdf" \
       "$file"
    
    if [ -f "${file%.pdf}_min.pdf" ]; then
      mv "${file%.pdf}_min.pdf" "$file"
      echo "완료: $file"
    else
      echo "오류: $file 압축 실패"
    fi
  fi
done

echo "모든 PDF 파일 압축 완료!"
