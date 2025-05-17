#!/usr/bin/env bash

# Installer for "Resize Images" Nautilus Script
# Author: Omid Khalili, inspired by the initial work of Vladislav Grigoryev
# License: GNU General Public License (GPL) version 3+
# Description: Resize images by percentage or size using ImageMagick via Nautilus
# Dependencies: bash, coreutils, ImageMagick, nautilus, zenity

SCRIPT_DIR="$HOME/.local/share/nautilus/scripts"
SCRIPT_PATH="$SCRIPT_DIR/Resize Images"

echo "📂 Creating scripts directory if it doesn't exist..."
mkdir -p "$SCRIPT_DIR"

echo "✍️ Writing 'Resize Images' script..."
cat > "$SCRIPT_PATH" << 'EOF'
#!/usr/bin/env bash

# "Resize Images" Nautilus script
# Author: Omid Khalili, inspired by Vladislav Grigoryev
# License: GNU General Public License (GPL) version 3+
# Description: Resize images by percentage or size using ImageMagick via Nautilus
# Dependencies: bash, coreutils, ImageMagick, nautilus, zenity

IMG_PATHS="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS}"
DEFAULT_SIZE="1024"
PERCENT_OPTIONS=(10% 20% 30% 40% 50% 60% 70% 80% 90%)
SIZE_OPTIONS=(
    640x480 800x600 1024x768 1280x720 1366x768
    1440x900 1600x1200 1920x1080 2560x1440 3840x2160
)

choose_mode() {
    zenity --list \
        --title="Select Resize Mode" \
        --text="Resize mode for $(wc -l <<< "$IMG_PATHS") file(s):" \
        --radiolist \
        --column="Select" --column="Mode" \
        TRUE "Percentage" FALSE "Size"
}

resize_by_percentage() {
    FORM_OUTPUT=$(zenity --forms \
        --title="Resize by Percentage" \
        --text="Select a percentage:" \
        --ok-label="Resize" \
        --add-combo="Percentage" \
        --combo-values="$(IFS="|"; echo "${PERCENT_OPTIONS[*]}")" \
        --add-list="Output Mode" \
        --list-values="copy / default|replace") || return 1

    IFS="|" read -r IMG_SIZE OUTPUT_MODE <<< "$FORM_OUTPUT"
    RESIZE_MODE="percentage"
}

resize_by_size() {
    FORM_OUTPUT=$(zenity --forms \
        --title="Resize by Size" \
        --text="Select a predefined size or enter custom dimensions:" \
        --ok-label="Resize" \
        --add-combo="Predefined Size" \
        --combo-values="$(IFS="|"; echo "${SIZE_OPTIONS[*]}")" \
        --add-entry="Width" \
        --add-entry="Height" \
        --add-list="Output Mode" \
        --list-values="copy / default|replace") || return 1

    IFS="|" read -r PRE_SIZE WIDTH HEIGHT OUTPUT_MODE <<< "$FORM_OUTPUT"
    if [[ -n "$WIDTH" || -n "$HEIGHT" ]]; then
        IMG_SIZE="${WIDTH}x${HEIGHT}"
    else
        IMG_SIZE="${PRE_SIZE:-${DEFAULT_SIZE}x${DEFAULT_SIZE}}"
    fi
    RESIZE_MODE="size"
}

process_images() {
    while IFS= read -r FILE; do
        OUTPUT_FILE="${FILE%/*}/resized.${FILE##*/}"
        convert "$FILE" -resize "$IMG_SIZE" "$OUTPUT_FILE"
        [[ "$OUTPUT_MODE" == "replace" ]] && mv -f "$OUTPUT_FILE" "$FILE"
    done <<< "$IMG_PATHS" | zenity --progress \
        --pulsate \
        --auto-close \
        --no-cancel \
        --title="Image Resize" \
        --text="Processing images..."
}

main() {
    MODE=$(choose_mode) || exit 1

    case "$MODE" in
        "Percentage") resize_by_percentage ;;
        "Size")       resize_by_size ;;
        *)            exit 1 ;;
    esac

    process_images
}

main
exit 0
EOF

echo "🔓 Making script executable..."
chmod +x "$SCRIPT_PATH"

echo "✅ Installation complete! Right-click an image → Scripts → Resize Images"
