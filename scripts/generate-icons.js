/**
 * PWA Icon Generator for ARC Bot
 * Generates all required icon sizes from the source logo
 * 
 * Usage: node scripts/generate-icons.js
 * Requires: npm install sharp
 */

const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const SOURCE_ICON = path.join(__dirname, '..', 'assets', 'pinecone-logo.png');
const OUTPUT_DIR = path.join(__dirname, '..', 'assets', 'icons');

// Standard icon sizes for PWA
const ICON_SIZES = [72, 96, 120, 128, 144, 152, 167, 180, 192, 384, 512];

// Maskable icon sizes (need safe area padding)
const MASKABLE_SIZES = [192, 512];

// Ensure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

async function generateIcons() {
  console.log('Generating PWA icons from:', SOURCE_ICON);
  console.log('Output directory:', OUTPUT_DIR);
  console.log('---');

  // Generate standard icons
  for (const size of ICON_SIZES) {
    const outputPath = path.join(OUTPUT_DIR, `icon-${size}.png`);
    await sharp(SOURCE_ICON)
      .resize(size, size, {
        fit: 'contain',
        background: { r: 26, g: 26, b: 26, alpha: 1 } // #1a1a1a
      })
      .png()
      .toFile(outputPath);
    console.log(`✓ Generated: icon-${size}.png`);
  }

  // Generate maskable icons (with safe area padding - 10% on each side)
  for (const size of MASKABLE_SIZES) {
    const outputPath = path.join(OUTPUT_DIR, `icon-maskable-${size}.png`);
    const innerSize = Math.floor(size * 0.8); // 80% of total size for content
    
    // Create icon with padding for maskable safe zone
    await sharp(SOURCE_ICON)
      .resize(innerSize, innerSize, {
        fit: 'contain',
        background: { r: 0, g: 0, b: 0, alpha: 0 }
      })
      .extend({
        top: Math.floor((size - innerSize) / 2),
        bottom: Math.ceil((size - innerSize) / 2),
        left: Math.floor((size - innerSize) / 2),
        right: Math.ceil((size - innerSize) / 2),
        background: { r: 26, g: 26, b: 26, alpha: 1 } // #1a1a1a
      })
      .png()
      .toFile(outputPath);
    console.log(`✓ Generated: icon-maskable-${size}.png (maskable)`);
  }

  // Generate Apple touch icon (180x180 is the standard)
  const appleTouchPath = path.join(OUTPUT_DIR, 'apple-touch-icon.png');
  await sharp(SOURCE_ICON)
    .resize(180, 180, {
      fit: 'contain',
      background: { r: 26, g: 26, b: 26, alpha: 1 }
    })
    .png()
    .toFile(appleTouchPath);
  console.log('✓ Generated: apple-touch-icon.png');

  // Generate favicon (32x32)
  const faviconPath = path.join(OUTPUT_DIR, 'favicon-32.png');
  await sharp(SOURCE_ICON)
    .resize(32, 32, {
      fit: 'contain',
      background: { r: 26, g: 26, b: 26, alpha: 1 }
    })
    .png()
    .toFile(faviconPath);
  console.log('✓ Generated: favicon-32.png');

  // Generate favicon (16x16)
  const favicon16Path = path.join(OUTPUT_DIR, 'favicon-16.png');
  await sharp(SOURCE_ICON)
    .resize(16, 16, {
      fit: 'contain',
      background: { r: 26, g: 26, b: 26, alpha: 1 }
    })
    .png()
    .toFile(favicon16Path);
  console.log('✓ Generated: favicon-16.png');

  console.log('---');
  console.log('Done! All icons generated successfully.');
}

generateIcons().catch(err => {
  console.error('Error generating icons:', err);
  process.exit(1);
});

