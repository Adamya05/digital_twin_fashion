#!/bin/bash

# Generate Mock 3D Model Files
# Creates realistic GLB model files for different products and quality levels

MODEL_DIR="/workspace/digital_twin_fashion/assets/products/3d"
COMPRESSED_DIR="$MODEL_DIR/compressed"

# Create directories
mkdir -p "$MODEL_DIR/clothing"/{tops,dresses,outerwear,activewear,bottoms}
mkdir -p "$COMPRESSED_DIR"

# Product definitions
declare -A PRODUCTS=(
    # Tops
    ["tshirt_men_basic_black"]="tops:black:men:28000:1.2"
    ["tshirt_men_basic_white"]="tops:white:men:28000:1.2"
    ["blouse_women_silk_red"]="tops:red:women:35000:1.4"
    ["blouse_women_cotton_white"]="tops:white:women:35000:1.4"
    ["tank_top_men_athletic_white"]="tops:white:men:22000:0.7"
    
    # Dresses
    ["dress_women_casual_blue"]="dresses:blue:women:55000:1.9"
    ["dress_women_formal_black"]="dresses:black:women:65000:2.2"
    ["dress_women_casual_floral"]="dresses:floral:women:58000:2.0"
    
    # Bottoms
    ["jeans_men_classic_blue"]="bottoms:blue:men:40000:1.3"
    ["jeans_women_skinny_black"]="bottoms:black:women:42000:1.4"
    ["pants_men_dress_gray"]="bottoms:gray:men:35000:1.2"
    ["shorts_men_athletic_gray"]="bottoms:gray:men:20000:0.8"
    ["shorts_women_denim_blue"]="bottoms:blue:women:22000:0.9"
    
    # Outerwear
    ["jacket_men_blazer_black"]="outerwear:black:men:48000:2.1"
    ["jacket_women_leather_brown"]="outerwear:brown:women:52000:2.3"
    ["jacket_men_denim_blue"]="outerwear:blue:men:42000:1.5"
    ["coat_women_winter_beige"]="outerwear:beige:women:60000:2.4"
    
    # Activewear
    ["sports_bra_women_black"]="activewear:black:women:18000:0.8"
    ["leggings_women_black"]="activewear:black:women:30000:1.0"
    ["hoodie_unisex_gray"]="outerwear:gray:unisex:38000:1.4"
)

# Quality levels and their file size multipliers
declare -A QUALITY_LEVELS=(
    ["ultra"]="2.0"
    ["high"]="1.5"
    ["medium"]="1.0"
    ["low"]="0.6"
)

# Generate GLB header function
generate_glb_header() {
    # GLB file format header: magic number + version + length placeholder
    printf '\x67\x6c\x62\x01'  # 'glb' + version 1
    printf '\x00\x00\x00\x00'  # Length placeholder (4 bytes)
}

# Generate GLB content
generate_glb_content() {
    local base_size=$1
    local polygon_count=$2
    local quality_multiplier=$3
    
    local actual_size=$(echo "scale=0; $base_size * 1024 * 1024 * $quality_multiplier / 1" | bc)
    
    # Generate realistic GLB content
    # JSON chunk
    local json_chunk_size=$(echo "scale=0; $actual_size * 0.3 / 1" | bc)
    generate_json_chunk $json_chunk_size
    
    # Binary chunk (mesh data)
    local binary_chunk_size=$(echo "scale=0; $actual_size * 0.7 / 1" | bc)
    generate_binary_chunk $binary_chunk_size $polygon_count
}

# Generate JSON chunk with model metadata
generate_json_chunk() {
    local size=$1
    local json_content='{"asset":{"version":"2.0","generator":"3D Fashion Studio"},"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0,"name":"clothing_item"}],"meshes":[{"primitives":[{"attributes":{"POSITION":0,"NORMAL":1,"TEXCOORD_0":2},"indices":3}],"name":"clothing_mesh","extras":{"polygon_count":'$2',"material_properties":{"stiffness":0.6,"stretch_factor":1.2,"texture_resolution":"2K"}}}],"buffers":[],"bufferViews":[],"accessors":[],"materials":[],"textures":[]}'
    
    printf "%s" "$json_content"
    
    # Pad to required size
    local remaining=$(echo "$size - ${#json_content}" | bc)
    if [ $remaining -gt 0 ]; then
        printf "%*s" $remaining | tr ' ' '\x00'
    fi
}

# Generate binary chunk with mesh data
generate_binary_chunk() {
    local size=$1
    local polygon_count=$2
    
    # Generate realistic binary data
    for ((i=0; i<$size; i++)); do
        # Create somewhat realistic vertex data patterns
        local value=$(( (i * 7 + $polygon_count % 1000) % 256 ))
        printf "\\x%02x" $value
    done
}

# Create model file
create_model_file() {
    local product_id=$1
    local category=$2
    local color=$3
    local gender=$4
    local polygon_count=$5
    local base_size_mb=$6
    local quality=$7
    local quality_multiplier=${QUALITY_LEVELS[$quality]}
    
    local base_size=$(echo "$base_size_mb * 1024 * 1024" | bc)
    local filename="${product_id}_${quality}_v1.glb"
    local filepath="$MODEL_DIR/clothing/$category/$filename"
    local compressed_filepath="$COMPRESSED_DIR/${product_id}_${quality}_compressed.glb"
    
    echo "Creating: $filename (${quality}x, ${base_size_mb}MB -> $(echo "scale=1; $base_size_mb * $quality_multiplier" | bc)MB)"
    
    # Generate GLB file
    {
        generate_glb_header
        generate_glb_content $base_size $polygon_count $quality_multiplier
    } > "$filepath"
    
    # Create compressed version (smaller)
    {
        generate_glb_header
        generate_glb_content $base_size $polygon_count $(echo "$quality_multiplier * 0.3" | bc)
    } > "$compressed_filepath"
}

# Generate all models
echo "Generating 3D Product Models..."
echo "================================"

total_files=0
for product_id in "${!PRODUCTS[@]}"; do
    IFS=':' read -r category color gender polygon_count base_size_mb <<< "${PRODUCTS[$product_id]}"
    
    for quality in "${!QUALITY_LEVELS[@]}"; do
        create_model_file "$product_id" "$category" "$color" "$gender" "$polygon_count" "$base_size_mb" "$quality"
        ((total_files++))
    done
done

echo ""
echo "================================"
echo "Generation Complete!"
echo "Total model files created: $total_files"
echo ""
echo "Directory structure:"
echo "├── clothing/"
ls -la "$MODEL_DIR/clothing/"
echo "├── compressed/"
ls -la "$COMPRESSED_DIR/"
echo "├── metadata/"
ls "$MODEL_DIR/metadata/" | head -5
echo "..."
echo ""
echo "3D Product Models are ready for use!"

# Generate a catalog file
echo "Creating product catalog..."

cat > "$MODEL_DIR/product_catalog.json" << 'EOF'
{
  "version": "1.0",
  "generated_date": "2024-11-02T19:31:46Z",
  "total_products": 15,
  "total_models": 60,
  "categories": {
    "tops": {"products": 5, "models_per_product": 4},
    "dresses": {"products": 3, "models_per_product": 4},
    "bottoms": {"products": 5, "models_per_product": 4},
    "outerwear": {"products": 4, "models_per_product": 4},
    "activewear": {"products": 2, "models_per_product": 4}
  },
  "quality_levels": ["ultra", "high", "medium", "low"],
  "file_formats": ["glb"],
  "optimization": {
    "compression": "KTX2",
    "lod_levels": 3,
    "vertex_compression": true
  }
}
EOF

echo "Product catalog created: $MODEL_DIR/product_catalog.json"