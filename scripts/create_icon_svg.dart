import 'dart:io';

void main() {
  // Create a simple SVG icon that can be converted to PNG
  final svgContent = '''
<svg width="512" height="512" xmlns="http://www.w3.org/2000/svg">
  <!-- Background -->
  <defs>
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#4CAF50;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#45a049;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Background rounded rectangle -->
  <rect width="512" height="512" rx="112" ry="112" fill="url(#bgGradient)"/>
  
  <!-- Cash Register / POS Terminal Icon -->
  <g transform="translate(128, 140)">
    <!-- Main body -->
    <rect x="0" y="80" width="256" height="160" rx="12" fill="white" opacity="0.95"/>
    
    <!-- Screen -->
    <rect x="20" y="100" width="216" height="80" rx="8" fill="#2196F3"/>
    
    <!-- Display text lines -->
    <rect x="40" y="115" width="120" height="8" rx="4" fill="white" opacity="0.7"/>
    <rect x="40" y="135" width="160" height="8" rx="4" fill="white" opacity="0.7"/>
    <rect x="40" y="155" width="90" height="8" rx="4" fill="white" opacity="0.7"/>
    
    <!-- Keypad buttons -->
    <circle cx="50" cy="210" r="12" fill="#E0E0E0"/>
    <circle cx="90" cy="210" r="12" fill="#E0E0E0"/>
    <circle cx="130" cy="210" r="12" fill="#E0E0E0"/>
    <circle cx="170" cy="210" r="12" fill="#E0E0E0"/>
    <circle cx="210" cy="210" r="12" fill="#E0E0E0"/>
    
    <!-- Receipt paper -->
    <rect x="100" y="0" width="56" height="90" rx="6" fill="white" opacity="0.9"/>
    <line x1="110" y1="20" x2="146" y2="20" stroke="#666" stroke-width="2"/>
    <line x1="110" y1="30" x2="146" y2="30" stroke="#666" stroke-width="2"/>
    <line x1="110" y1="40" x2="135" y2="40" stroke="#666" stroke-width="2"/>
    <line x1="110" y1="50" x2="146" y2="50" stroke="#666" stroke-width="2"/>
    
    <!-- Paper tear edge -->
    <path d="M 100 85 L 105 90 L 110 85 L 115 90 L 120 85 L 125 90 L 130 85 L 135 90 L 140 85 L 145 90 L 150 85 L 156 90" 
          fill="none" stroke="white" stroke-width="2"/>
  </g>
  
  <!-- Dollar sign accent -->
  <g transform="translate(380, 380)">
    <circle cx="40" cy="40" r="45" fill="white" opacity="0.2"/>
    <text x="40" y="60" font-family="Arial" font-size="60" font-weight="bold" 
          fill="white" text-anchor="middle">\$</text>
  </g>
</svg>
''';

  // Save SVG file
  final svgFile = File('assets/images/icon.svg');
  svgFile.writeAsStringSync(svgContent);
  
  print('✓ Created icon.svg in assets/images/');
  print('');
  print('Next steps:');
  print('1. Convert SVG to PNG (512x512): Use online converter like https://cloudconvert.com/svg-to-png');
  print('2. Or use a design tool to create icon.png and icon_foreground.png');
  print('3. Run: flutter pub get');
  print('4. Run: dart run flutter_launcher_icons');
  print('');
  print('For production, consider using a professional design tool for better quality.');
}
