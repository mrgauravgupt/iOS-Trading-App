#!/bin/bash
echo "=== MODEL AUDIT REPORT ===" > model_audit.txt
echo "Generated: $(date)" >> model_audit.txt
echo "" >> model_audit.txt

echo "1. DUPLICATE STRUCT DEFINITIONS:" >> model_audit.txt
echo "MarketDataPoint occurrences:" >> model_audit.txt
grep -r "struct MarketDataPoint" --include="*.swift" . >> model_audit.txt
echo "" >> model_audit.txt

echo "Pattern struct occurrences:" >> model_audit.txt
grep -r "struct.*Pattern" --include="*.swift" . >> model_audit.txt
echo "" >> model_audit.txt

echo "Trade struct occurrences:" >> model_audit.txt
grep -r "struct.*Trade" --include="*.swift" . >> model_audit.txt
echo "" >> model_audit.txt

echo "2. IMPORT STATEMENT ANALYSIS:" >> model_audit.txt
echo "SharedCoreModels imports:" >> model_audit.txt
grep -r "import SharedCoreModels" --include="*.swift" . | wc -l >> model_audit.txt
echo "" >> model_audit.txt

echo "Potentially problematic imports:" >> model_audit.txt
grep -r "import.*Models" --include="*.swift" . | grep -v "SharedCoreModels" >> model_audit.txt
echo "" >> model_audit.txt

echo "3. DIRECTORY STRUCTURE:" >> model_audit.txt
find . -type d -name "*Model*" >> model_audit.txt

echo "Audit complete. Check model_audit.txt"
