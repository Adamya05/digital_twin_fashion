#!/usr/bin/env python3
"""
App Icon Generator for Digital Twin Fashion
Generates adaptive launcher icons for different densities
"""

import os
from PIL import Image, ImageDraw, ImageFont
import io

def create_icon(size, background_color, foreground_color):
    """Create an app icon with background and foreground elements"""
    
    # Create base image
    img = Image.new('RGBA', (size, size), background_color)
    draw = ImageDraw.Draw(img)
    
    # Calculate dimensions
    margin = size // 8
    center = size // 2
    icon_size = size - (margin * 2)
    
    # Draw background circle
    draw.ellipse([margin, margin, size-margin, size-margin], fill=background_color)
    
    # Draw fashion icon (stylized shirt)
    shirt_width = icon_size // 2
    shirt_height = int(icon_size * 0.7)
    shirt_x = center - shirt_width // 2
    shirt_y = center - shirt_height // 2 + size // 16
    
    # Shirt body
    draw.rectangle([shirt_x, shirt_y + shirt_height//3, 
                   shirt_x + shirt_width, shirt_y + shirt_height], 
                  fill=foreground_color)
    
    # Shirt sleeves
    sleeve_width = shirt_width // 3
    draw.rectangle([shirt_x - sleeve_width, shirt_y + shirt_height//3,
                   shirt_x, shirt_y + shirt_height//2], fill=foreground_color)
    draw.rectangle([shirt_x + shirt_width, shirt_y + shirt_height//3,
                   shirt_x + shirt_width + sleeve_width, shirt_y + shirt_height//2], 
                  fill=foreground_color)
    
    # Shirt collar
    collar_size = shirt_width // 6
    draw.polygon([(center - collar_size, shirt_y),
                 (center + collar_size, shirt_y),
                 (center, shirt_y + collar_size)], fill=background_color)
    
    # Draw 3D cube for digital twin
    cube_size = icon_size // 3
    cube_x = center - cube_size // 2
    cube_y = shirt_y - cube_size - size // 16
    
    # Cube main face
    draw.rectangle([cube_x, cube_y, cube_x + cube_size, cube_y + cube_size], 
                  fill=foreground_color, outline=background_color, width=2)
    
    # Cube top face (diamond shape)
    draw.polygon([(cube_x + cube_size//2, cube_y - cube_size//4),
                 (cube_x + cube_size + cube_size//4, cube_y + cube_size//2),
                 (cube_x + cube_size//2, cube_y + cube_size + cube_size//4),
                 (cube_x - cube_size//4, cube_y + cube_size//2)], 
                fill=foreground_color, outline=background_color, width=1)
    
    return img

def generate_all_icons():
    """Generate icons for all densities"""
    
    # Color scheme
    background_color = (255, 255, 255, 255)  # White
    primary_color = (33, 150, 243, 255)      # Blue
    
    # Define icon sizes for different densities
    densities = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192
    }
    
    # Create directories
    for density in densities:
        os.makedirs(f'/workspace/digital_twin_fashion/android/app/src/main/res/mipmap-{density}', 
                   exist_ok=True)
    
    # Generate icons for each density
    for density, size in densities.items():
        print(f"Generating {density} icon ({size}x{size})")
        
        icon = create_icon(size, background_color, primary_color)
        
        # Save as PNG
        icon_path = f'/workspace/digital_twin_fashion/android/app/src/main/res/mipmap-{density}/ic_launcher.png'
        icon.save(icon_path, 'PNG')
        print(f"Saved: {icon_path}")
    
    print("✅ All icons generated successfully!")

if __name__ == '__main__':
    generate_all_icons()