#!/usr/bin/env python3
"""
Optimize app icons for RuraCamp suite.
- Resize main icons to 1024x1024 (max needed for App Store/Play Store)
- Generate launcher icons for Android (mipmap folders)
- Generate iOS app icons
"""

import os
from PIL import Image

# Base directory
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Icon paths
ICONS = {
    'rurarain': os.path.join(BASE_DIR, 'apps/rurarain/assets/images/rurarain-icon.png'),
    'rurarubber': os.path.join(BASE_DIR, 'apps/rurarubber/assets/images/rurarubber-icon.png'),
    'ruracamp': os.path.join(BASE_DIR, 'packages/agro_core/assets/images/ruracamp-icon.png'),
}

# Android mipmap sizes
ANDROID_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# iOS sizes
IOS_SIZES = {
    'Icon-App-20x20@1x': 20,
    'Icon-App-20x20@2x': 40,
    'Icon-App-20x20@3x': 60,
    'Icon-App-29x29@1x': 29,
    'Icon-App-29x29@2x': 58,
    'Icon-App-29x29@3x': 87,
    'Icon-App-40x40@1x': 40,
    'Icon-App-40x40@2x': 80,
    'Icon-App-40x40@3x': 120,
    'Icon-App-60x60@2x': 120,
    'Icon-App-60x60@3x': 180,
    'Icon-App-76x76@1x': 76,
    'Icon-App-76x76@2x': 152,
    'Icon-App-83.5x83.5@2x': 167,
    'Icon-App-1024x1024@1x': 1024,
}

def optimize_icon(input_path, output_path, target_size=1024):
    """Resize and optimize a PNG icon."""
    img = Image.open(input_path)

    # Convert to RGBA if not already
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    # Resize using high-quality Lanczos resampling
    img = img.resize((target_size, target_size), Image.Resampling.LANCZOS)

    # Save with optimization
    img.save(output_path, 'PNG', optimize=True)

    return os.path.getsize(output_path)

def generate_android_icons(source_path, app_dir, background_color):
    """Generate Android launcher icons from source."""
    img = Image.open(source_path)

    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    for folder, size in ANDROID_SIZES.items():
        # Create mipmap directory
        mipmap_dir = os.path.join(app_dir, 'android/app/src/main/res', folder)
        os.makedirs(mipmap_dir, exist_ok=True)

        # Resize icon
        resized = img.resize((size, size), Image.Resampling.LANCZOS)

        # Create background and composite
        bg = Image.new('RGBA', (size, size), background_color + (255,))
        bg.paste(resized, (0, 0), resized)

        # Convert to RGB (no alpha) for launcher icons
        final = bg.convert('RGB')

        # Save
        output_path = os.path.join(mipmap_dir, 'ic_launcher.png')
        final.save(output_path, 'PNG', optimize=True)
        print(f"    {folder}/ic_launcher.png ({size}x{size})")

def generate_ios_icons(source_path, app_dir, background_color):
    """Generate iOS app icons from source."""
    img = Image.open(source_path)

    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    # iOS icon directory
    ios_dir = os.path.join(app_dir, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    os.makedirs(ios_dir, exist_ok=True)

    for name, size in IOS_SIZES.items():
        resized = img.resize((size, size), Image.Resampling.LANCZOS)

        # iOS needs solid background
        bg = Image.new('RGBA', (size, size), background_color + (255,))
        bg.paste(resized, (0, 0), resized)
        final = bg.convert('RGB')

        output_path = os.path.join(ios_dir, f'{name}.png')
        final.save(output_path, 'PNG', optimize=True)

    print(f"    Generated {len(IOS_SIZES)} iOS icons")

def main():
    print("=" * 50)
    print("RuraCamp Icon Optimization")
    print("=" * 50)

    # 1. Optimize main icons (resize to 1024x1024)
    print("\n1. Optimizing main icons to 1024x1024...")
    for name, path in ICONS.items():
        if os.path.exists(path):
            original_size = os.path.getsize(path)
            new_size = optimize_icon(path, path, 1024)
            reduction = (1 - new_size / original_size) * 100
            print(f"   {name}: {original_size/1024/1024:.1f}MB -> {new_size/1024:.0f}KB ({reduction:.1f}% reduction)")
        else:
            print(f"   {name}: NOT FOUND")

    # 2. Generate Android launcher icons
    print("\n2. Generating Android launcher icons...")

    rurarain_path = ICONS['rurarain']
    if os.path.exists(rurarain_path):
        print("   RuraRain (green background):")
        generate_android_icons(rurarain_path, os.path.join(BASE_DIR, 'apps/rurarain'), (76, 175, 80))

    rurarubber_path = ICONS['rurarubber']
    if os.path.exists(rurarubber_path):
        print("   RuraRubber (brown background):")
        generate_android_icons(rurarubber_path, os.path.join(BASE_DIR, 'apps/rurarubber'), (121, 85, 72))

    # 3. Generate iOS icons
    print("\n3. Generating iOS app icons...")

    if os.path.exists(rurarain_path):
        print("   RuraRain:")
        generate_ios_icons(rurarain_path, os.path.join(BASE_DIR, 'apps/rurarain'), (76, 175, 80))

    if os.path.exists(rurarubber_path):
        print("   RuraRubber:")
        generate_ios_icons(rurarubber_path, os.path.join(BASE_DIR, 'apps/rurarubber'), (121, 85, 72))

    print("\n" + "=" * 50)
    print("Done!")
    print("=" * 50)

if __name__ == '__main__':
    main()
