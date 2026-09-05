#!/bin/bash
# build-query.sh - 编译 rime-query
# 用法: build-query.sh <编译器> <编译参数> <include路径> <lib路径> <输出目录>

set -e

if [ $# -lt 5 ]; then
    echo "用法: $0 <编译器> <编译参数> <include路径> <lib路径> <输出目录>"
    exit 1
fi

COMPILER="$1"
FLAGS="$2"
INCLUDE_DIR="$3"
LIB_DIR="$4"
OUTPUT_DIR="$5"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SRC_FILE="$PROJECT_DIR/cpp/rime-query.cc"

mkdir -p "$OUTPUT_DIR"

$COMPILER $FLAGS \
    -I"$PROJECT_DIR/cpp/3rd" \
    -I"$INCLUDE_DIR" \
    "$SRC_FILE" \
    -L"$LIB_DIR" -lrime \
    -o "$OUTPUT_DIR/rime-query"
