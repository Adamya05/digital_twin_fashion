#!/bin/bash

# Sample Avatar 3D Assets Generator
# This script creates placeholder GLB files and metadata for testing

ASSETS_DIR="/workspace/digital_twin_fashion/assets/avatars"
MODELS_DIR="$ASSETS_DIR/models"
THUMBNAILS_DIR="$ASSETS_DIR/thumbnails"
FALLBACKS_DIR="$ASSETS_DIR/fallbacks"
COMPRESSED_DIR="$ASSETS_DIR/compressed"

echo "Creating sample avatar 3D assets..."

# Create directory structure if not exists
mkdir -p "$MODELS_DIR" "$THUMBNAILS_DIR" "$FALLBACKS_DIR" "$COMPRESSED_DIR"

# Sample avatar configurations
declare -a AVATARS=(
    "slim_male_160:Slim Male 160cm:160:Slim:Male"
    "slim_female_162:Slim Female 162cm:162:Slim:Female"
    "regular_male_175:Regular Male 175cm:175:Regular:Male"
    "regular_female_168:Regular Female 168cm:168:Regular:Female"
    "athletic_male_180:Athletic Male 180cm:180:Athletic:Male"
    "athletic_female_170:Athletic Female 170cm:170:Athletic:Female"
    "plussize_male_172:Plus Size Male 172cm:172:PlusSize:Male"
    "plussize_female_165:Plus Size Female 165cm:165:PlusSize:Female"
    "tall_male_185:Tall Male 185cm:185:Regular:Male"
    "tall_female_178:Tall Female 178cm:178:Regular:Female"
    "petite_male_155:Petite Male 155cm:155:Slim:Male"
    "petite_female_152:Petite Female 152cm:152:Slim:Female"
    "muscular_male_178:Muscular Male 178cm:178:Athletic:Male"
    "muscular_female_172:Muscular Female 172cm:172:Athletic:Female"
)

# Fallback model configurations
declare -a FALLBACKS=(
    "placeholder_slim:Slim Placeholder:Slim"
    "placeholder_regular:Regular Placeholder:Regular"
    "placeholder_athletic:Athletic Placeholder:Athletic"
    "placeholder_plussize:Plus Size Placeholder:PlusSize"
)

# Generate sample avatar GLB files
for avatar_config in "${AVATARS[@]}"; do
    IFS=':' read -r id name height body_type gender <<< "$avatar_config"
    
    # Create placeholder GLB file (minimal valid GLB structure)
    output_file="$MODELS_DIR/${id}_model.glb"
    
    # Create minimal GLB file with basic structure
    python3 -c "
import struct
import os

# GLB header
magic = b'glTF'  # 4 bytes
version = 2  # 4 bytes (uint32)
length = 1024  # 4 bytes (uint32) - placeholder length

# JSON chunk
json_data = '''{
    \"asset\": {
        \"version\": \"2.0\",
        \"generator\": \"Sample Avatar Generator\"
    },
    \"scene\": 0,
    \"scenes\": [{\"nodes\": [0]}],
    \"nodes\": [{\"mesh\": 0}],
    \"meshes\": [{
        \"primitives\": [{
            \"attributes\": {
                \"POSITION\": 0
            }
        }]
    }],
    \"accessors\": [{
        \"bufferView\": 0,
        \"componentType\": 5126,
        \"count\": 1,
        \"type\": \"VEC3\"
    }],
    \"bufferViews\": [{
        \"buffer\": 0,
        \"byteOffset\": 0,
        \"byteLength\": 12
    }],
    \"buffers\": [{
        \"byteLength\": 12
    }]
}'''

json_bytes = json_data.encode('utf-8')
json_padding = (4 - (len(json_bytes) % 4)) % 4
json_chunk_length = len(json_bytes) + json_padding
json_chunk_type = b'JSON'

# BIN chunk (empty)
bin_bytes = b'\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00'
bin_padding = (4 - (len(bin_bytes) % 4)) % 4
bin_chunk_length = len(bin_bytes) + bin_padding
bin_chunk_type = b'BIN\\x00'

# Write GLB file
with open('$output_file', 'wb') as f:
    # Header
    f.write(magic)
    f.write(struct.pack('<I', version))
    f.write(struct.pack('<I', 12 + 8 + json_chunk_length + 8 + bin_chunk_length))
    
    # JSON chunk
    f.write(struct.pack('<I', json_chunk_length))
    f.write(json_chunk_type)
    f.write(json_bytes)
    f.write(b' ' * json_padding)  # Padding
    
    # BIN chunk
    f.write(struct.pack('<I', bin_chunk_length))
    f.write(bin_chunk_type)
    f.write(bin_bytes)
    f.write(b'\\x00' * bin_padding)  # Padding

print(f'Created: $output_file')
"
    
    # Create metadata JSON file
    metadata_file="$MODELS_DIR/${id}_metadata.json"
    cat > "$metadata_file" << EOF
{
    "id": "$id",
    "name": "$name",
    "height": $height,
    "bodyType": "$body_type",
    "gender": "$gender",
    "fileSize": 2048576,
    "polyCount": 15000,
    "qualityLevel": "High",
    "textures": ["diffuse", "normal", "roughness", "metallic"],
    "created": "$(date -Iseconds)",
    "optimized": true,
    "mobileOptimized": true
}
EOF
    
    # Create placeholder thumbnail
    thumb_file="$THUMBNAILS_DIR/${id}_thumb.png"
    python3 -c "
from PIL import Image, ImageDraw, ImageFont
import os

# Create 256x256 thumbnail
img = Image.new('RGB', (256, 256), color='white')
draw = ImageDraw.Draw(img)

# Simple avatar silhouette
draw.ellipse([60, 40, 196, 120], fill='lightgray', outline='black', width=2)  # Head
draw.rectangle([100, 120, 156, 180], fill='lightgray', outline='black', width=2)  # Body
draw.rectangle([110, 180, 130, 220], fill='lightgray', outline='black', width=2)  # Left leg
draw.rectangle([136, 180, 156, 220], fill='lightgray', outline='black', width=2)  # Right leg

# Add text
try:
    font = ImageFont.load_default()
    text = '$body_type $gender'
    draw.text((10, 230), text, fill='black', font=font)
except:
    draw.text((10, 230), '$body_type $gender', fill='black')

img.save('$thumb_file')
print(f'Created thumbnail: $thumb_file')
"
    
    echo "Created avatar: $id ($name)"
done

# Generate fallback models
for fallback_config in "${FALLBACKS[@]}"; do
    IFS=':' read -r id name body_type <<< "$fallback_config"
    
    fallback_file="$FALLBACKS_DIR/${id}.glb"
    
    # Create simplified fallback GLB
    python3 -c "
import struct

# Simple placeholder GLB for fallback
json_data = '''{
    \"asset\": {\"version\": \"2.0\", \"generator\": \"Fallback Model\"},
    \"scene\": 0,
    \"scenes\": [{\"nodes\": [0]}],
    \"nodes\": [{\"mesh\": 0}],
    \"meshes\": [{\"primitives\": [{\"attributes\": {\"POSITION\": 0}}]}],
    \"accessors\": [{\"bufferView\": 0, \"componentType\": 5126, \"count\": 8, \"type\": \"VEC3\"}],
    \"bufferViews\": [{\"buffer\": 0, \"byteOffset\": 0, \"byteLength\": 96}],
    \"buffers\": [{\"byteLength\": 96}]
}'''

json_bytes = json_data.encode('utf-8')
json_padding = (4 - (len(json_bytes) % 4)) % 4
json_chunk_length = len(json_bytes) + json_padding

# Simple cube vertices
bin_data = struct.pack('<24f', 
    -1,-1,-1,  1,-1,-1,  1,1,-1,  -1,1,-1,  # Front
    -1,-1,1,   1,-1,1,    1,1,1,   -1,1,1    # Back
)
bin_padding = (4 - (len(bin_data) % 4)) % 4

with open('$fallback_file', 'wb') as f:
    f.write(b'glTF')
    f.write(struct.pack('<I', 2))
    f.write(struct.pack('<I', 12 + 8 + json_chunk_length + 8 + len(bin_data) + bin_padding))
    
    f.write(struct.pack('<I', json_chunk_length))
    f.write(b'JSON')
    f.write(json_bytes)
    f.write(b' ' * json_padding)
    
    f.write(struct.pack('<I', len(bin_data) + bin_padding))
    f.write(b'BIN\\x00')
    f.write(bin_data)
    f.write(b'\\x00' * bin_padding)

print(f'Created fallback: $fallback_file')
"
    
    # Create 2D placeholder
    placeholder_2d="$FALLBACKS_DIR/placeholder_2d.png"
    python3 -c "
from PIL import Image, ImageDraw
img = Image.new('RGB', (256, 256), color='lightblue')
draw = ImageDraw.Draw(img)
draw.text((50, 120), '2D Placeholder', fill='black')
draw.ellipse([80, 40, 176, 100], fill='lightgray', outline='black', width=3)
img.save('$placeholder_2d')
print(f'Created 2D placeholder: $placeholder_2d')
"
    
    echo "Created fallback: $id ($name)"
done

# Generate compressed versions (simulate compression by copying with _compressed suffix)
for glb_file in "$MODELS_DIR"/*.glb; do
    if [[ -f "$glb_file" ]]; then
        filename=$(basename "$glb_file")
        compressed_file="$COMPRESSED_DIR/${filename%.glb}_compressed.glb"
        cp "$glb_file" "$compressed_file"
        
        # Add compression metadata
        compressed_meta="${compressed_file%.glb}_info.json"
        cat > "$compressed_meta" << EOF
{
    "originalFile": "$glb_file",
    "compressedFile": "$compressed_file",
    "compressionRatio": 0.75,
    "originalSize": 2048576,
    "compressedSize": 1536432,
    "compressionType": "gzip",
    "qualityLevel": "medium"
}
EOF
    fi
done

# Create avatar catalog/index
echo "Creating avatar catalog..."
cat > "$ASSETS_DIR/avatar_catalog.json" << EOF
{
    "version": "1.0",
    "generated": "$(date -Iseconds)",
    "totalAvatars": ${#AVATARS[@]},
    "avatars": [
EOF

first=true
for avatar_config in "${AVATARS[@]}"; do
    IFS=':' read -r id name height body_type gender <<< "$avatar_config"
    if [[ "$first" == false ]]; then echo "," >> "$ASSETS_DIR/avatar_catalog.json"; fi
    first=false
    cat >> "$ASSETS_DIR/avatar_catalog.json" << EOF
        {
            "id": "$id",
            "name": "$name",
            "modelFile": "models/${id}_model.glb",
            "thumbnailFile": "thumbnails/${id}_thumb.png",
            "height": $height,
            "bodyType": "$body_type",
            "gender": "$gender",
            "category": "${body_type}_${gender}",
            "tags": ["3d", "$body_type", "$gender", "mobile-optimized"],
            "quality": "high",
            "mobileOptimized": true,
            "textureFormats": ["png", "jpg"]
        }
EOF
done

cat >> "$ASSETS_DIR/avatar_catalog.json" << EOF
    ],
    "fallbackModels": [
        {
            "id": "placeholder_slim",
            "name": "Slim Placeholder",
            "file": "fallbacks/placeholder_slim.glb",
            "bodyType": "Slim",
            "description": "Generic slim body type placeholder"
        },
        {
            "id": "placeholder_regular", 
            "name": "Regular Placeholder",
            "file": "fallbacks/placeholder_regular.glb",
            "bodyType": "Regular",
            "description": "Generic regular body type placeholder"
        },
        {
            "id": "placeholder_athletic",
            "name": "Athletic Placeholder", 
            "file": "fallbacks/placeholder_athletic.glb",
            "bodyType": "Athletic",
            "description": "Generic athletic body type placeholder"
        },
        {
            "id": "placeholder_plussize",
            "name": "Plus Size Placeholder",
            "file": "fallbacks/placeholder_plussize.glb", 
            "bodyType": "PlusSize",
            "description": "Generic plus size body type placeholder"
        }
    ],
    "metadata": {
        "totalModels": ${#AVATARS[@]},
        "totalFallbacks": ${#FALLBACKS[@]},
        "supportedFormats": ["glb", "gltf"],
        "textureFormats": ["png", "jpg"],
        "maxFileSize": "50MB",
        "recommendedCacheSize": "500MB",
        "mobileOptimized": true
    }
}
EOF

echo "✅ Sample avatar 3D assets generated successfully!"
echo "📁 Location: $ASSETS_DIR"
echo "📊 Total avatars: ${#AVATARS[@]}"
echo "🔄 Fallback models: ${#FALLBACKS[@]}"
echo "📱 Mobile optimized: Yes"
echo "🗂️  Structure:"
echo "  ├── models/        (${#AVATARS[@]} avatar GLB files)"
echo "  ├── thumbnails/    (${#AVATARS[@]} preview images)"  
echo "  ├── fallbacks/     (${#FALLBACKS[@]} placeholder models + 2D)"
echo "  ├── compressed/    (compressed versions)"
echo "  └── avatar_catalog.json (asset index)"
