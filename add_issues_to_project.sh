#!/bin/bash

# Add all 23 issues to GitHub Project

PROJECT_NUMBER=2
OWNER="vinothvsbe"
REPO="TravelCompanion"

echo "🚀 Adding all 23 issues to GitHub Project..."
echo ""

for i in {1..23}; do
  echo "Adding issue #$i..."
  gh project item-add $PROJECT_NUMBER --owner $OWNER --url "https://github.com/$OWNER/$REPO/issues/$i" 2>&1 | tail -1
  sleep 1
done

echo ""
echo "✅ All 23 issues added to project!"
echo ""
echo "View project at: https://github.com/users/$OWNER/projects/$PROJECT_NUMBER"
