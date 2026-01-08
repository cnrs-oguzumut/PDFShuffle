# App Store Screenshots

## Files Ready for Upload

### Main Screenshot (Required)
- `screenshot-1-main.png` - 1440 x 900 pixels
- `screenshot-1-main@2x.png` - 2880 x 1800 pixels (Retina)

## How to Upload to App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Click on "PDFGenie Plus"
3. Click on "1.0 Prepare for Submission"
4. Scroll to "App Screenshots" section
5. Click "+" to add screenshots
6. Upload **at least 3 screenshots** (you can upload the same one multiple times for now, or take more screenshots showing different modes)

## App Store Requirements

For macOS apps, you need:
- **Minimum 3 screenshots**
- **Size**: At least 1280 x 800 pixels
- **Format**: PNG or JPEG
- **Recommended**: Show different features (Split, Merge, Extract, Reorder modes)

## Tips

To capture more screenshots:
1. Run the app: `open build/PDFGenie+.app`
2. Switch between tabs (Split, Merge, Extract, Reorder)
3. Take screenshots with Cmd+Shift+4 (drag to select window)
4. Resize screenshots to 1440 x 900 or 2880 x 1800 using:
   ```bash
   sips -z 900 1440 your-screenshot.png --out screenshot-2.png
   ```

## Current Screenshot Shows
- Main interface with all 4 modes visible
- Dark mode design
- PDFGenie+ branding
