#!/usr/bin/bash

# Installer for "Resize Images" Nautilus Script
# Coded by: Omid Khalili <omid[dot]1985[at]gmail[dot]com>
# License: GNU General Public License (GPL) version 3+
# Description: Resize images by percentage or size using ImageMagick from Nautilus
# Requires: bash coreutils ImageMagick nautilus zenity

SCRIPT_DIR="$HOME/.local/share/nautilus/scripts"
SCRIPT_PATH="$SCRIPT_DIR/Resize Images"

echo "📂 Creating scripts directory if it doesn't exist..."
mkdir -p "$SCRIPT_DIR"

echo "✍️ Writing Resize Images script..."
cat > "$SCRIPT_PATH" << 'EOF'
#!/usr/bin/bash

# Coded by: Omid Khalili <omid[dot]1985[at]gmail[dot]com>
# License: GNU General Public License (GPL) version 3+
# Description: Resize images by percentage or size using ImageMagick from Nautilus
# Requires: bash coreutils ImageMagick nautilus zenity

IMG_PATH="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS/%$'\n'/}"
IMG_DSIZE="1024"
IMG_PERCENTAGES=(10% 20% 30% 40% 50% 60% 70% 80% 90%)
IMG_SIZES=(
    640x480 800x600 1024x768 1280x720 1366x768
    1440x900 1600x1200 1920x1080 2560x1440 3840x2160
)

script_init() {
    MODE=$(zenity --list \
        --title="Select Resize Mode" \
        --text="Resize mode for $(wc -l <<< "${IMG_PATH}") file(s):" \
        --radiolist \
        --column="Pick" --column="Mode" \
        TRUE "Percentage" FALSE "Size")

    if [ -z "$MODE" ]; then
        return 1  # Cancelled
    fi

    if [ "$MODE" = "Percentage" ]; then
        FORM_OUTPUT=$(zenity --forms \
            --title="Resize by Percentage" \
            --text="Choose a percentage:" \
            --ok-label="Resize" \
            --add-combo="Percentage" \
            --combo-values="$(IFS="|"; echo "${IMG_PERCENTAGES[*]}")" \
            --add-list="Output" \
            --list-values="copy / default|replace") || return 1
        IFS="|" read -r IMG_SIZE IMG_OUT <<< "$FORM_OUTPUT"
        RESIZE_MODE="percentage"
    elif [ "$MODE" = "Size" ]; then
        FORM_OUTPUT=$(zenity --forms \
            --title="Resize by Size" \
            --text="Choose fixed size or custom dimensions:" \
            --ok-label="Resize" \
            --add-combo="Size" \
            --combo-values="$(IFS="|"; echo "${IMG_SIZES[*]}")" \
            --add-entry="Width" \
            --add-entry="Height" \
            --add-list="Output" \
            --list-values="copy / default|replace") || return 1
        IFS="|" read -r IMG_SIZE IMG_WSIZE IMG_HSIZE IMG_OUT <<< "$FORM_OUTPUT"
        if [ -n "$IMG_WSIZE" ] || [ -n "$IMG_HSIZE" ]; then
            IMG_SIZE="${IMG_WSIZE}x${IMG_HSIZE}"
        fi
        if [ -z "${IMG_SIZE/ /}" ]; then
            IMG_SIZE="${IMG_DSIZE}x${IMG_DSIZE}"
        fi
        RESIZE_MODE="size"
    else
        return 1
    fi
}

script_exec() {
    while read -r IMG_PATH; do
        IMG_OPATH="${IMG_PATH%/*}/resized.${IMG_PATH##*/}"
        convert "${IMG_PATH}" -resize "${IMG_SIZE}" "${IMG_OPATH}"
        if [ "${IMG_OUT}" = "replace" ]; then
            mv -f "${IMG_OPATH}" "${IMG_PATH}"
        fi
    done <<< "${IMG_PATH}" | zenity \
        --progress \
        --pulsate \
        --auto-close \
        --no-cancel \
        --title="Image Resize" \
        --text="Processing files..."
}

if script_init; then
    script_exec
fi

exit 0
EOF

echo "🔓 Making the script executable..."
chmod +x "$SCRIPT_PATH"

echo "🔄 Exiting Nautilus to apply changes..."
nautilus -q 

echo "✅ Done! Now right-click an image → Scripts → Resize Images"
