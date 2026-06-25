#!/usr/bin/env python3
from PIL import Image
import os

# Color
PRIMARY_COLOR = '#4F46E5'

# Load the logo
logo_path = 'assets/workbyte-purple.png'
logo = Image.open(logo_path).convert('RGBA')

# Icon sizes for each resolution
icon_sizes = {
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
}

# Create icons
for icon_path, size in icon_sizes.items():
    # Create background
    bg = Image.new('RGB', (size, size), 'white')
    
    # Scale logo to 85% of the icon size
    logo_size = int(size * 0.85)
    logo_resized = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    
    # Calculate position to center the logo
    offset = (size - logo_size) // 2
    
    # Paste logo onto background
    bg.paste(logo_resized, (offset, offset), logo_resized)
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(icon_path), exist_ok=True)
    
    # Save icon
    bg.save(icon_path)
    print(f'Generated {icon_path}')

print('All icons generated successfully!')
