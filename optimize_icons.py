import os
from PIL import Image

def optimize_icon(path, output_path, size=(512, 512)):
    try:
        if not os.path.exists(path):
            print(f"File not found: {path}")
            return False
            
        img = Image.open(path)
        print(f"Original size: {img.size}")
        
        # Resize with high quality resampling
        img = img.resize(size, Image.Resampling.LANCZOS)
        
        # Save optimized
        img.save(output_path, optimize=True)
        print(f"Saved optimized icon to {output_path}")
        return True
    except Exception as e:
        print(f"Error optimizing {path}: {e}")
        return False

def add_padding(path, output_path, padding_factor=1.5, final_size=(1024, 1024)):
    try:
        if not os.path.exists(path):
            print(f"File not found: {path}")
            return False
            
        img = Image.open(path)
        print(f"Original foreground size: {img.size}")
        
        # Create new canvas
        # If original is WxH, new canvas will be (W*factor)x(H*factor)
        # But we want the visual logical size to be 'final_size' with padding
        
        # Better approach:
        # Resize the LOGO down to be smaller within the final_size canvas.
        # Standard Adaptive Icon is 108x108 dp. The inner 72dp is the safe zone.
        # So the content should fit within approx 66% of the full image to be safe.
        
        # Let's target the content being ~60% of the canvas width
        target_content_size = int(final_size[0] * 0.60)
        
        # Resize original image to this target content size (keeping aspect ratio)
        aspect = img.width / img.height
        if aspect > 1:
            new_w = target_content_size
            new_h = int(target_content_size / aspect)
        else:
            new_h = target_content_size
            new_w = int(target_content_size * aspect)
            
        img_resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Create transparent canvas
        canvas = Image.new('RGBA', final_size, (0, 0, 0, 0))
        
        # Center the resized image on canvas
        x = (final_size[0] - new_w) // 2
        y = (final_size[1] - new_h) // 2
        
        canvas.paste(img_resized, (x, y), img_resized if img_resized.mode == 'RGBA' else None)
        
        canvas.save(output_path, optimize=True)
        print(f"Saved padded foreground to {output_path}")
        return True
    except Exception as e:
        print(f"Error adding padding to {path}: {e}")
        return False

# Paths
base_dir = r"c:\Users\jelui\AntiGravity\PlanejaCampo"
borracha_assets = os.path.join(base_dir, "apps", "planejaaborracha", "assets", "images")
chuva_assets = os.path.join(base_dir, "apps", "planejachuva", "assets", "images")

# 1. Optimize PlanejaBorracha Main Icon (Login/In-App)
# Input: planejaborracha-icon.png (6MB) -> Output: Same (overwrite) or new file?
# Let's overwrite safely by renaming original first
icon_path = os.path.join(borracha_assets, "planejaborracha-icon.png")
icon_backup = os.path.join(borracha_assets, "planejaborracha-icon.bak.png")

if os.path.exists(icon_path):
    if not os.path.exists(icon_backup):
        os.rename(icon_path, icon_backup)
        print(f"Backed up {icon_path}")
    
    # Use backup as source
    optimize_icon(icon_backup, icon_path, size=(512, 512))

# 2. Optimize PlanejaChuva Main Icon (Just in case)
chuva_icon_path = os.path.join(chuva_assets, "planejachuva-icon.png")
chuva_icon_backup = os.path.join(chuva_assets, "planejachuva-icon.bak.png")

if os.path.exists(chuva_icon_path):
    # Check size? Just optimize to be safe
    if not os.path.exists(chuva_icon_backup):
        os.rename(chuva_icon_path, chuva_icon_backup)
        print(f"Backed up {chuva_icon_path}")
    
    optimize_icon(chuva_icon_backup, chuva_icon_path, size=(512, 512))

# 3. Create Padded Foreground for Launcher
# Source: planejaborracha-icon-adaptive-foreground.png
# We want to create a NEW file: planejaborracha-icon-adaptive-foreground-padded.png
fg_path = os.path.join(borracha_assets, "planejaborracha-icon-adaptive-foreground.png")
fg_padded_path = os.path.join(borracha_assets, "planejaborracha-icon-adaptive-foreground-padded.png")

if os.path.exists(fg_path):
    add_padding(fg_path, fg_padded_path, final_size=(1024, 1024))
