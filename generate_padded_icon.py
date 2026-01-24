from PIL import Image
import os

def add_padding(input_path, output_path, padding_ratio=0.3):
    """
    Adds transparent padding to an image to make the content smaller relative to the canvas.
    Useful for Android Adaptive Icons which mask the edges.
    
    padding_ratio: Float, percentage of the total size to be padding. 
                   0.3 means 30% padding (15% on each side).
    """
    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Calculate new size based on creating a larger canvas
        # If we want the original image to shrink, we effectively place it in a larger canvas and resize down,
        # or place it in a larger canvas and keep it same size (effectively adding margin).
        # We need the final output to be the same resolution or high enough.
        # Let's create a new canvas where the original image fits in the center safe zone.
        
        # Adaptive icons safe zone is roughly 66% of the diameter.
        # So if we want the current content to fit safely, we should increase canvas size.
        
        new_width = int(width * (1 + padding_ratio))
        new_height = int(height * (1 + padding_ratio))
        
        # Center position
        x_offset = (new_width - width) // 2
        y_offset = (new_height - height) // 2
        
        new_img = Image.new("RGBA", (new_width, new_height), (0, 0, 0, 0))
        new_img.paste(img, (x_offset, y_offset))
        
        # Optional: Resize back to original size if specific dimensions are needed, 
        # but for launcher generator usually high res is fine.
        # However, to avoid huge files, let's keep it reasonable. 
        # If original was 512, new is ~665. That's fine.
        
        new_img.save(output_path)
        print(f"Created padded icon: {output_path}")

    except Exception as e:
        print(f"Error processing image: {e}")

# Paths
base_dir = r"c:\Users\jelui\AntiGravity\PlanejaCampo\apps\planejachuva\assets\images"
input_icon = os.path.join(base_dir, "planejachuva-icon-dark.png")
output_icon = os.path.join(base_dir, "planejachuva-icon-adaptive-foreground.png")

add_padding(input_icon, output_icon, padding_ratio=0.6) # 60% increase makes the logo roughly 62% of the new canvas (1/1.6), safe zone is 66%
