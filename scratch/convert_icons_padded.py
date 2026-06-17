import os
from PIL import Image

assets_dir = 'd:/Apps/FlutterApps/kaizen/assets'

for filename in os.listdir(assets_dir):
    if filename.startswith('logo') and filename.endswith('.png'):
        png_path = os.path.join(assets_dir, filename)
        ico_filename = filename.replace('.png', '.ico')
        ico_path = os.path.join(assets_dir, ico_filename)
        
        try:
            img = Image.open(png_path).convert('RGBA')
            
            # Original size
            max_size = max(img.size)
            
            # Add padding by making the canvas larger. 
            # E.g., if we want the logo to be 75% of the total size, we multiply by ~1.33
            padding_factor = 1.35
            new_size = int(max_size * padding_factor)
            
            new_img = Image.new('RGBA', (new_size, new_size), (0, 0, 0, 0))
            
            # Paste the original image centered
            paste_x = (new_size - img.size[0]) // 2
            paste_y = (new_size - img.size[1]) // 2
            
            # Use img as mask to preserve alpha transparency correctly
            new_img.paste(img, (paste_x, paste_y), img)
            
            # Save as ICO with multiple sizes
            icon_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
            new_img.save(ico_path, format='ICO', sizes=icon_sizes)
            print(f"Converted {filename} to {ico_filename} with padding")
        except Exception as e:
            print(f"Failed to convert {filename}: {e}")
