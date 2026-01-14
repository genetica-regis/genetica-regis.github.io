#!/bin/bash
# Genetica Regis - Cannabis Breeding Blog
# Requires: pandoc

set -e

BLOG_DIR="blogentries"
TEMPLATE="template.html"
ARCHIVE_TEMPLATE="archive-template.html"
OUTPUT="index.html"
ARCHIVE_OUTPUT="archive.html"

echo "🌿 Building Genetica Regis blog..."

# Find all *-template.html files (except template.html and archive-template.html)
PAGE_TEMPLATES=()
for tpl in ./*-template.html; do
  [ -f "$tpl" ] || continue
  base="$(basename "$tpl")"
  if [ "$base" = "template.html" ] || [ "$base" = "archive-template.html" ]; then
    continue
  fi
  PAGE_TEMPLATES+=("$tpl")
done

# Build menu/footer links dynamically
MENU_LINKS=( '<li><a href="index.html">Home</a></li>' '<li><a href="archive.html">Archive</a></li>' )
FOOTER_LINKS=( '<a href="index.html">Home</a> | <a href="archive.html">Archive</a>' )

for tpl in "${PAGE_TEMPLATES[@]}"; do
  PAGE="${tpl%-template.html}.html"
  NAME="$(basename "${tpl%-template.html}")"
  TITLE="$(echo "$NAME" | sed 's/.*/\u&/;s/-/ /g')"
  MENU_LINKS+=( "<li><a href=\"$PAGE\">$TITLE</a></li>" )
  FOOTER_LINKS+=( " | <a href=\"$PAGE\">$TITLE</a>" )
done

# Prepare temp files
cp "$TEMPLATE" "$OUTPUT"
printf -v MENU_LINKS_STR '%s\n' "${MENU_LINKS[@]}"
printf -v FOOTER_LINKS_STR '%s' "${FOOTER_LINKS[@]}"
echo -e "$MENU_LINKS_STR" > /tmp/menu_links.html
echo -e "$FOOTER_LINKS_STR" > /tmp/footer_links.html

# Pinned post (optional)
PINNED_MD="$BLOG_DIR/pinned.md"
PINNED_HTML=""
if [ -f "$PINNED_MD" ]; then
  PINNED_HTML="<div class=\"pinned-post\">$(pandoc "$PINNED_MD" -f markdown -t html --highlight-style=pygments)</div>"
fi
echo -e "$PINNED_HTML" > /tmp/pinned.html

# Collect blog entries (excluding home.md and pinned.md)
ENTRIES=()
for f in "$BLOG_DIR"/*.md; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  if [ "$base" = "home.md" ] || [ "$base" = "pinned.md" ]; then
    continue
  fi
  ENTRIES+=("$f")
done

# Sort entries by date, newest first
mapfile -t sorted < <(for f in "${ENTRIES[@]}"; do 
  DATE=$(head -n 6 "$f" | grep -E "(\*\*Date:\*\*|^[0-9]{4}-[0-9]{2}-[0-9]{2})" | head -n 1)
  if [[ $DATE == *"**Date:**"* ]]; then
    CLEAN_DATE=$(echo "$DATE" | sed 's/.*\*\*Date:\*\* \([0-9-]*\).*/\1/')
  else
    CLEAN_DATE="$DATE"
  fi
  echo "$f|$CLEAN_DATE"
done | sort -t'|' -k2 -r)

# Collect all unique tags
declare -A all_tags
for entry in "${sorted[@]}"; do
  [ -z "$entry" ] && continue
  f="${entry%%|*}"
  TAGS_LINE=$(head -n 10 "$f" | grep -E "^\*\*Tags:\*\*" | head -n 1)
  if [ -n "$TAGS_LINE" ]; then
    TAGS=$(echo "$TAGS_LINE" | sed 's/\*\*Tags:\*\* //' | tr ',' '\n' | sed 's/^ *//;s/ *$//')
    while IFS= read -r tag; do
      [ -n "$tag" ] && all_tags["$tag"]=1
    done <<< "$TAGS"
  fi
done

# Generate tag filter HTML
TAG_FILTER_HTML="<div class=\"tag-filter\">\n"
TAG_FILTER_HTML+="<div class=\"tag-filter-header\">\n"
TAG_FILTER_HTML+="<span class=\"tag-filter-title\">🏷️ Filter by Tag</span>\n"
TAG_FILTER_HTML+="</div>\n"
TAG_FILTER_HTML+="<div class=\"tag-filter-buttons\">\n"
TAG_FILTER_HTML+="<button class=\"tag-btn active\" data-tag=\"all\">All</button>\n"
for tag in $(printf '%s\n' "${!all_tags[@]}" | sort); do
  TAG_FILTER_HTML+="<button class=\"tag-btn\" data-tag=\"$tag\">$tag</button>\n"
done
TAG_FILTER_HTML+="</div>\n"
TAG_FILTER_HTML+="</div>\n"
echo -e "$TAG_FILTER_HTML" > /tmp/tagfilter.html

# Prepare all entries for home
LATEST_HTML=""
POSTNAV_HTML=""
for entry in "${sorted[@]}"; do
  [ -z "$entry" ] && continue
  f="${entry%%|*}"
  ID=$(basename "$f" .md)
  TITLE=$(head -n 1 "$f" | sed 's/^# //')
  
  # Extract tags for this entry
  TAGS_LINE=$(head -n 10 "$f" | grep -E "^\*\*Tags:\*\*" | head -n 1)
  ENTRY_TAGS=""
  if [ -n "$TAGS_LINE" ]; then
    ENTRY_TAGS=$(echo "$TAGS_LINE" | sed 's/\*\*Tags:\*\* //' | tr ',' ' ' | sed 's/  */ /g;s/^ *//;s/ *$//')
  fi
  
  ENTRY_HTML=$(pandoc "$f" -f markdown -t html --highlight-style=pygments)
  LATEST_HTML+="<section id=\"$ID\" class=\"blogentry\" data-tags=\"$ENTRY_TAGS\">$ENTRY_HTML</section>\n"
  POSTNAV_HTML+="<a href=\"#$ID\" class=\"post-nav-item\" data-target=\"$ID\" data-tags=\"$ENTRY_TAGS\">$TITLE</a>\n"
done
echo -e "$LATEST_HTML" > /tmp/latest.html
echo -e "$POSTNAV_HTML" > /tmp/postnav.html

# Prepare archive
ARCHIVE_HTML="<div class=\"archive-header\">\n"
ARCHIVE_HTML+="<h1>📁 Blog Archive</h1>\n"
ARCHIVE_HTML+="<p class=\"archive-description\">All posts organized by year. Click any post to read it.</p>\n"
ARCHIVE_HTML+="</div>\n"
ARCHIVE_HTML+="<div class=\"archive-content\">\n"

# Collect unique years
declare -A years
for entry in "${sorted[@]}"; do
  [ -z "$entry" ] && continue
  f="${entry%%|*}"
  DATE=$(head -n 6 "$f" | grep -E "(\*\*Date:\*\*|^[0-9]{4}-[0-9]{2}-[0-9]{2})" | head -n 1)
  if [[ $DATE == *"**Date:**"* ]]; then
    YR=$(echo "$DATE" | sed 's/.*\*\*Date:\*\* \([0-9]\{4\}\)-.*/\1/')
  else
    YR=$(echo "$DATE" | sed 's/^\([0-9]\{4\}\)-.*/\1/')
  fi
  [ -n "$YR" ] && years[$YR]=1
done

# Process each year
for YR in $(printf '%s\n' "${!years[@]}" | sort -nr); do
  YEAR_COUNT=0
  YEAR_POSTS=""
  
  for entry in "${sorted[@]}"; do
    [ -z "$entry" ] && continue
    f="${entry%%|*}"
    TITLE=$(head -n 1 "$f" | sed 's/^# //')
    DATE=$(head -n 6 "$f" | grep -E "(\*\*Date:\*\*|^[0-9]{4}-[0-9]{2}-[0-9]{2})" | head -n 1)
    ID=$(basename "$f" .md)
    
    if [[ $DATE == *"**Date:**"* ]]; then
      POST_YR=$(echo "$DATE" | sed 's/.*\*\*Date:\*\* \([0-9]\{4\}\)-.*/\1/')
      CLEAN_DATE=$(echo "$DATE" | sed 's/.*\*\*Date:\*\* \([0-9-]*\).*/\1/')
    else
      POST_YR=$(echo "$DATE" | sed 's/^\([0-9]\{4\}\)-.*/\1/')
      CLEAN_DATE="$DATE"
    fi
    
    if [ "$POST_YR" = "$YR" ]; then
      YEAR_COUNT=$((YEAR_COUNT + 1))
      FORMATTED_DATE=$(date -d "$CLEAN_DATE" "+%B %d" 2>/dev/null || echo "$CLEAN_DATE")
      # Get preview text (first paragraph after title/date/tags, max 120 chars)
      PREVIEW=$(sed -n '5,20p' "$f" | grep -v '^\*\*Date' | grep -v '^\*\*Tags' | grep -v '^#' | grep -v '^$' | head -n 2 | tr '\n' ' ' | cut -c1-120 | sed 's/[[:space:]]*$//')
      [ -n "$PREVIEW" ] && PREVIEW="$PREVIEW..."
      
      # Extract tags for archive post
      TAGS_LINE=$(head -n 10 "$f" | grep -E "^\*\*Tags:\*\*" | head -n 1)
      ARCHIVE_ENTRY_TAGS=""
      ARCHIVE_TAG_DISPLAY=""
      if [ -n "$TAGS_LINE" ]; then
        ARCHIVE_ENTRY_TAGS=$(echo "$TAGS_LINE" | sed 's/\*\*Tags:\*\* //' | tr ',' ' ' | sed 's/  */ /g;s/^ *//;s/ *$//')
        # Create tag display spans
        for atag in $ARCHIVE_ENTRY_TAGS; do
          ARCHIVE_TAG_DISPLAY+="<span class=\"archive-tag\">$atag</span>"
        done
      fi
      
      YEAR_POSTS+="<a href=\"index.html#$ID\" class=\"archive-post-link\" data-tags=\"$ARCHIVE_ENTRY_TAGS\">\n"
      YEAR_POSTS+="<article class=\"archive-post\">\n"
      YEAR_POSTS+="<div class=\"post-meta\">\n"
      YEAR_POSTS+="<span class=\"post-date\">$FORMATTED_DATE</span>\n"
      if [ -n "$ARCHIVE_TAG_DISPLAY" ]; then
        YEAR_POSTS+="<span class=\"post-tags\">$ARCHIVE_TAG_DISPLAY</span>\n"
      fi
      YEAR_POSTS+="</div>\n"
      YEAR_POSTS+="<h3 class=\"post-title\">$TITLE</h3>\n"
      YEAR_POSTS+="<p class=\"post-preview\">$PREVIEW</p>\n"
      YEAR_POSTS+="</article>\n"
      YEAR_POSTS+="</a>\n"
    fi
  done
  
  ARCHIVE_HTML+="<div class=\"archive-year\">\n"
  ARCHIVE_HTML+="<div class=\"year-header\">\n"
  ARCHIVE_HTML+="<h2 class=\"year-title\">$YR</h2>\n"
  ARCHIVE_HTML+="<span class=\"post-count\">$YEAR_COUNT posts</span>\n"
  ARCHIVE_HTML+="</div>\n"
  ARCHIVE_HTML+="<div class=\"posts-grid\">\n"
  ARCHIVE_HTML+="$YEAR_POSTS"
  ARCHIVE_HTML+="</div></div>\n"
done

ARCHIVE_HTML+="</div>\n"
echo -e "$ARCHIVE_HTML" > /tmp/archive.html

# Home page content
HOME_MD="$BLOG_DIR/home.md"
HOME_HTML=""
if [ -f "$HOME_MD" ]; then
  HOME_HTML="$(pandoc "$HOME_MD" -f markdown -t html --highlight-style=pygments)"
fi
echo -e "$HOME_HTML" > /tmp/home.html

# Build main index.html
sed -i "/<!--MENU-->/r /tmp/menu_links.html" "$OUTPUT"
sed -i "/<!--MENU-->/d" "$OUTPUT"
sed -i "/<!--FOOTERLINKS-->/r /tmp/footer_links.html" "$OUTPUT"
sed -i "/<!--FOOTERLINKS-->/d" "$OUTPUT"
sed -i "/<!--POSTNAV-->/r /tmp/postnav.html" "$OUTPUT"
sed -i "/<!--POSTNAV-->/d" "$OUTPUT"
sed -i "/<!--HOME-->/r /tmp/home.html" "$OUTPUT"
sed -i "/<!--TAGFILTER-->/r /tmp/tagfilter.html" "$OUTPUT"
sed -i "/<!--PINNED-->/r /tmp/pinned.html" "$OUTPUT"
sed -i "/<!--LATEST-->/r /tmp/latest.html" "$OUTPUT"
sed -i "/<!--ARCHIVE-->/r /tmp/archive.html" "$OUTPUT"
sed -i "/<!--HOME-->/d" "$OUTPUT"
sed -i "/<!--TAGFILTER-->/d" "$OUTPUT"
sed -i "/<!--PINNED-->/d" "$OUTPUT"
sed -i "/<!--LATEST-->/d" "$OUTPUT"
sed -i "/<!--ARCHIVE-->/d" "$OUTPUT"

# Build archive.html
cp "$ARCHIVE_TEMPLATE" "$ARCHIVE_OUTPUT"
sed -i "/<!--MENU-->/r /tmp/menu_links.html" "$ARCHIVE_OUTPUT"
sed -i "/<!--MENU-->/d" "$ARCHIVE_OUTPUT"
sed -i "/<!--FOOTERLINKS-->/r /tmp/footer_links.html" "$ARCHIVE_OUTPUT"
sed -i "/<!--FOOTERLINKS-->/d" "$ARCHIVE_OUTPUT"
sed -i "/<!--ARCHIVETAGFILTER-->/r /tmp/tagfilter.html" "$ARCHIVE_OUTPUT"
sed -i "/<!--ARCHIVETAGFILTER-->/d" "$ARCHIVE_OUTPUT"
sed -i "/<!--ARCHIVE-->/r /tmp/archive.html" "$ARCHIVE_OUTPUT"
sed -i "/<!--ARCHIVE-->/d" "$ARCHIVE_OUTPUT"

# Build custom pages from *-template.html
for tpl in "${PAGE_TEMPLATES[@]}"; do
  PAGE="${tpl%-template.html}.html"
  BASENAME="$(basename "${tpl%-template.html}")"
  MARKDOWN_DIR="${BASENAME}"
  PAGE_HTML=""
  
  if [ -d "$MARKDOWN_DIR" ]; then
    for md in "$MARKDOWN_DIR"/*.md; do
      [ -f "$md" ] || continue
      PAGE_HTML+="$(pandoc "$md" -f markdown -t html --highlight-style=pygments)\n"
    done
  fi
  
  cp "$tpl" "$PAGE"
  sed -i "/<!--MENU-->/r /tmp/menu_links.html" "$PAGE"
  sed -i "/<!--MENU-->/d" "$PAGE"
  sed -i "/<!--FOOTERLINKS-->/r /tmp/footer_links.html" "$PAGE"
  sed -i "/<!--FOOTERLINKS-->/d" "$PAGE"
  
  PLACEHOLDER="<!--${BASENAME^^}-->"
  printf '%b' "$PAGE_HTML" > /tmp/page_content.html
  MARKER="__REPLACE_MARKER__"
  sed -i "s|$PLACEHOLDER|$MARKER|" "$PAGE"
  sed -i "/$MARKER/r /tmp/page_content.html" "$PAGE"
  sed -i "/$MARKER/d" "$PAGE"
done

# Cleanup
rm -f /tmp/home.html /tmp/pinned.html /tmp/latest.html /tmp/archive.html \
      /tmp/menu_links.html /tmp/footer_links.html /tmp/page_content.html \
      /tmp/postnav.html /tmp/tagfilter.html 2>/dev/null || true

# Generate transparency manifest
if [ -f "./generate-manifest.sh" ]; then
  bash ./generate-manifest.sh
fi

echo "✅ Site built successfully!"
echo "   - $OUTPUT"
echo "   - $ARCHIVE_OUTPUT"
for tpl in "${PAGE_TEMPLATES[@]}"; do
  echo "   - ${tpl%-template.html}.html"
done
echo ""
echo "🌐 To preview: python3 -m http.server 8000"
