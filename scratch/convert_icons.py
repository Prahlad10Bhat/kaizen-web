import os
from PIL import Image

assets_dir = 'd:/Apps/FlutterApps/kaizen/assets'

for filename in os.listdir(assets_dir):
    if filename.startswith('logo') and filename.endswith('.png'):
        png_path = os.path.join(assets_dir, filename)
        ico_filename = filename.replace('.png', '.ico')
        ico_path = os.path.join(assets_dir, ico_filename)
        
        try:
            img = Image.open(png_path)
            # Make sure it's square
            max_size = max(img.size)
            new_img = Image.new('RGBA', (max_size, max_size), (0, 0, 0, 0))
            new_img.paste(img, ((max_size - img.size[0]) // 2, (max_size - img.size[1]) // 2))
            
            # Save as ICO with multiple sizes
            icon_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
            new_img.save(ico_path, format='ICO', sizes=icon_sizes)
            print(f"Converted {filename} to {ico_filename}")
        except Exception as e:
            print(f"Failed to convert {filename}: {e}")
