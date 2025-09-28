#!/bin/bash
echo "Fixing import statements..."

# Replace incorrect imports
find . -name "*.swift" -exec sed -i '' 's/import SharedModels/import SharedCoreModels/g' {} \;
find . -name "*.swift" -exec sed -i '' 's/import CoreModels/import SharedCoreModels/g' {} \;
find . -name "*.swift" -exec sed -i '' 's/import Models/import SharedCoreModels/g' {} \;

echo "Import statements fixed"
