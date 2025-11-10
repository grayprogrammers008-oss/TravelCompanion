#!/usr/bin/env python3
"""
Simple App Icon Generator for Pathio
Creates a 1024x1024 PNG app icon for App Store submission
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon():
    # Create 1024x1024 image
    size = 1024
    image = Image.new('RGB', (size, size), color='#2196F3')  # Material Blue
    draw = ImageDraw.Draw(image)

    # Draw a simple path/route icon
    # Create a winding path design
    path_color = '#FFFFFF'
    path_width = 80

    # Draw curved path
    points = [
        (200, 800),
        (300, 600),
        (400, 500),
        (500, 520),
        (600, 450),
        (700, 400),
        (800, 350),
    ]

    # Draw path segments
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=path_color, width=path_width)

    # Draw location markers
    marker_positions = [(200, 800), (800, 350)]
    marker_radius = 60

    for pos in marker_positions:
        # Outer circle (white)
        draw.ellipse(
            [pos[0]-marker_radius, pos[1]-marker_radius,
             pos[0]+marker_radius, pos[1]+marker_radius],
            fill='#FFFFFF'
        )
        # Inner circle (blue)
        inner_radius = marker_radius - 15
        draw.ellipse(
            [pos[0]-inner_radius, pos[1]-inner_radius,
             pos[0]+inner_radius, pos[1]+inner_radius],
            fill='#2196F3'
        )

    # Try to add text
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 180)
        text = "P"
        # Get text bounding box
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]

        # Center text
        text_x = (size - text_width) // 2
        text_y = (size - text_height) // 2 - 50

        # Draw text with shadow
        draw.text((text_x+5, text_y+5), text, fill='#1976D2', font=font)
        draw.text((text_x, text_y), text, fill='#FFFFFF', font=font)
    except:
        # If font not available, just skip text
        pass

    # Save icon
    output_path = os.path.join(os.path.dirname(__file__), 'AppIcon-1024x1024.png')
    image.save(output_path, 'PNG')
    print(f"✅ App icon created: {output_path}")
    return output_path

if __name__ == '__main__':
    create_app_icon()
