#!/bin/bash
# =============================================================================
# Script  : 04 - Log Analyzer
# Concepts: while-read loop, grep, counter variables, file reading
# Purpose : Read Apache log file line by line and count keyword occurrences
# Usage   : bash 04_log_analyzer.sh [log_file]
# =============================================================================

# ----- Determine log file path (argument > system > sample) -----

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

LOGFILE=${1:-"/var/log/apache2/error.log"}

# If default doesn't exist, try sample data
if [ ! -f "$LOGFILE" ]; then
    LOGFILE="$PROJECT_DIR/sample_data/sample_error.log"
fi

# ----- Error handling: check file exists -----

if [ ! -f "$LOGFILE" ]; then
    echo "[ERROR] Log file not found: $LOGFILE"
    echo "Usage: bash $0 [path_to_log_file]"
    exit 1
fi

echo "=============================================="
echo "       APACHE LOG ANALYZER"
echo "=============================================="
echo ""
echo "  Analyzing: $LOGFILE"
echo ""

# ----- Initialize counter variables -----

TOTAL_LINES=0
ERROR_COUNT=0
WARNING_COUNT=0
NOTICE_COUNT=0
INFO_COUNT=0
CRITICAL_COUNT=0
AUTH_ERROR_COUNT=0
FILE_NOT_FOUND=0

# =============================================================================
# Main analysis: while-read loop
# Reads the file line by line using: while IFS= read -r LINE
# IFS=   prevents leading/trailing whitespace from being stripped
# -r     prevents backslash from being interpreted as escape
# =============================================================================

if [ ! -s "$LOGFILE" ]; then
  echo "File is empty"
  exit 1
fi

while IFS= read -r LINE; do
    # Count every line
    TOTAL_LINES=$((TOTAL_LINES + 1))

    # grep -iq does case-insensitive quiet match on each line
    # If the pattern matches, increment the counter

    echo "$LINE" | grep -iq "\[crit" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
    echo "$LINE" | grep -iq "\[error" && ERROR_COUNT=$((ERROR_COUNT + 1))
    echo "$LINE" | grep -iq "\[warn" && WARNING_COUNT=$((WARNING_COUNT + 1))
    echo "$LINE" | grep -iq "\[notice" && NOTICE_COUNT=$((NOTICE_COUNT + 1))
    echo "$LINE" | grep -iq "\[info" && INFO_COUNT=$((INFO_COUNT + 1))

    # Specific error types
    echo "$LINE" | grep -iq "denied\|authz\|AH01630" && AUTH_ERROR_COUNT=$((AUTH_ERROR_COUNT + 1))
    echo "$LINE" | grep -iq "File does not exist\|AH00128" && FILE_NOT_FOUND=$((FILE_NOT_FOUND + 1))

done < "$LOGFILE"

# =============================================================================
# Display results
# =============================================================================

echo "--- Analysis Results ---"
echo ""
echo "  Total lines read     : $TOTAL_LINES"
echo ""
echo "  By Severity:"
echo "    Critical           : $CRITICAL_COUNT"
echo "    Errors             : $ERROR_COUNT"
echo "    Warnings           : $WARNING_COUNT"
echo "    Notices            : $NOTICE_COUNT"
echo "    Info               : $INFO_COUNT"
echo ""
echo "  By Type:"
echo "    Auth/Access denied : $AUTH_ERROR_COUNT"
echo "    File not found     : $FILE_NOT_FOUND"
echo ""

# ----- Summary based on count -----

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "  [ALERT] Critical errors found — immediate attention needed!"
elif [ "$ERROR_COUNT" -gt 5 ]; then
    echo "  [WARNING] High error count — review recommended."
elif [ "$ERROR_COUNT" -gt 0 ]; then
    echo "  [INFO] Some errors found — monitor situation."
else
    echo "  [OK] No errors detected."
fi

echo ""

# ----- Show 5 most recent errors -----

echo "--- 5 Most Recent Errors ---"
echo ""

KEYWORD="error"
grep -i "$KEYWORD" "$LOGFILE" 2>/dev/null | tail -5 | while IFS= read -r MATCH; do
    echo "  > $(echo "$MATCH" | cut -c 1-80)"
done

echo ""
echo "  Total matches for '$KEYWORD': $(grep -ci "$KEYWORD" "$LOGFILE" 2>/dev/null)"
echo ""
echo "=============================================="
echo "  Analysis complete."
echo "=============================================="
