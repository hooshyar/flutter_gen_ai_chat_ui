# 📸 Social Media Assets Guide

**Purpose:** Visual assets for Day 5 launch and ongoing promotion
**Status:** Ready to create
**Priority:** HIGH (needed before launch)

---

## 🎯 Required Assets

### 1. Twitter Header Image (REQUIRED)
**Dimensions:** 1500 x 500 px
**Format:** PNG or JPG
**File size:** <5 MB

**Content:**
- Package name: "flutter_gen_ai_chat_ui"
- Tagline: "ChatGPT Integration for Flutter in 3 Lines"
- Visual: Code snippet + chat UI screenshot
- Brand colors: Flutter blue (#02569B) + OpenAI green (#10A37F)

**Design Mockup:**
```
┌───────────────────────────────────────────────────────────────┐
│                                                               │
│   flutter_gen_ai_chat_ui                                      │
│   Add ChatGPT to Flutter in 3 Lines of Code                  │
│                                                               │
│   [Code Snippet]              [Chat UI Screenshot]           │
│   OpenAIChatWidget(           [Mobile phone mockup]          │
│     apiKey: env.key,          [showing ChatGPT-like chat]    │
│     currentUser: user,                                        │
│   )                                                           │
│                                                               │
│   ⭐ Star on GitHub  📦 pub.dev/packages/flutter_gen_ai...   │
└───────────────────────────────────────────────────────────────┘
```

**Tools to create:**
- Canva (easiest): https://canva.com
- Figma (professional): https://figma.com
- Photoshop (advanced)

---

### 2. Dev.to Cover Image (REQUIRED)
**Dimensions:** 1000 x 420 px
**Format:** PNG or JPG
**Aspect ratio:** ~2.38:1

**Content:**
- Article title: "ChatGPT Integration for Flutter in 3 Lines"
- Subtitle: "Security-First, Production-Ready, Open Source"
- Visual: Split screen - code on left, chat UI on right
- Author credit: "by @hooshyar"

**Design Mockup:**
```
┌─────────────────────────────────────────────────────┐
│ ChatGPT Integration for Flutter in 3 Lines          │
│ Security-First • Production-Ready • Open Source     │
│                                                     │
│  Code:                    Result:                   │
│  ┌─────────────────┐     ┌──────────────┐         │
│  │ OpenAIChatWidget│     │ [Chat UI]    │         │
│  │   apiKey: key   │     │ User: Hello  │         │
│  │   currentUser...│     │ AI: Hi there!│         │
│  └─────────────────┘     └──────────────┘         │
│                                                     │
│  by @hooshyar                    #flutter #ai      │
└─────────────────────────────────────────────────────┘
```

---

### 3. GitHub Social Preview (REQUIRED)
**Dimensions:** 1280 x 640 px
**Format:** PNG
**Location:** Settings → Social Preview

**Content:**
- Package logo/icon (if exists)
- Name: "flutter_gen_ai_chat_ui"
- Tagline: "Flutter chat UI kit with built-in AI integration"
- Key features: "OpenAI • Claude • Gemini • Streaming • Markdown"
- Stars count (dynamically updated by GitHub)

**Design Mockup:**
```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  [Icon]  flutter_gen_ai_chat_ui                          │
│                                                          │
│  Flutter chat UI kit with built-in AI integration        │
│                                                          │
│  ✅ OpenAI Integration  ✅ Streaming Animation          │
│  ✅ Security-First      ✅ Production-Ready              │
│                                                          │
│  [Screenshot of chat interface]                          │
│                                                          │
│  ⭐ [XXX] stars  •  🍴 [XX] forks  •  📄 MIT License    │
└──────────────────────────────────────────────────────────┘
```

---

### 4. Twitter Post Image (OPTIONAL but RECOMMENDED)
**Dimensions:** 1200 x 675 px
**Format:** PNG or JPG
**Aspect ratio:** 16:9

**Content:**
- Before/After comparison
- OR: Code snippet with result
- OR: Feature highlights
- OR: Performance benchmarks

**Design Mockup (Comparison):**
```
┌───────────────────────────────────────────────────────────┐
│                                                           │
│  Building AI Chat:                                        │
│                                                           │
│  Without flutter_gen_ai_chat_ui:                          │
│  ❌ 3-4 days of integration work                         │
│  ❌ Custom streaming logic                               │
│  ❌ Security vulnerabilities                             │
│  ❌ No token tracking                                    │
│                                                           │
│  With flutter_gen_ai_chat_ui:                            │
│  ✅ 3 lines of code                                      │
│  ✅ Built-in streaming                                   │
│  ✅ Security-first approach                              │
│  ✅ Automatic cost tracking                              │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

---

### 5. LinkedIn Post Image (OPTIONAL)
**Dimensions:** 1200 x 627 px
**Format:** PNG or JPG
**Tone:** Professional, business-focused

**Content:**
- Professional headline: "Launching flutter_gen_ai_chat_ui v2.5.0"
- Subheading: "Open Source Flutter Package for AI Integration"
- Key stat: "3 lines of code • 400+ lines security docs • Production-ready"
- Professional aesthetic (clean, minimal)

---

## 📱 Screenshots Needed

### Priority 1: Core Functionality (REQUIRED)

**Screenshot 1: ChatGPT Clone Example**
- Device: iPhone or Android emulator
- Content: Full conversation showing:
  - User message
  - AI streaming response (mid-animation)
  - Multiple messages showing markdown formatting
  - Code block with syntax highlighting
- Annotations: Arrow pointing to streaming text with "Real-time streaming"

**Screenshot 2: Code Example**
- IDE: VS Code or Android Studio
- File: `main.dart` showing the 3-line setup
- Syntax highlighting ON
- Optional: Terminal showing `flutter run` command

**Screenshot 3: Security Warning**
- Show the security alert dialog
- Text visible: "⚠️ Security Notice: Never hardcode API keys"
- Professional, trust-building

### Priority 2: Advanced Features (RECOMMENDED)

**Screenshot 4: Token Usage**
- Console output showing token counting
- Format: "Used 150 tokens ($0.0003)"
- Demonstrates cost tracking

**Screenshot 5: Dark Mode**
- Same chat interface in dark mode
- Shows theme flexibility

**Screenshot 6: Performance Benchmarks**
- Flutter DevTools performance tab
- Timeline showing 60 FPS
- Memory usage graph
- Annotated: "Smooth 60 FPS with 1,000 messages"

### Priority 3: Comparison (OPTIONAL)

**Screenshot 7: Comparison Table**
- Side-by-side: flutter_gen_ai_chat_ui vs competitors
- Highlights unique features

---

## 🎨 Design Guidelines

### Color Palette

**Primary Colors:**
- Flutter Blue: `#02569B` (main brand)
- OpenAI Green: `#10A37F` (AI theme)
- White: `#FFFFFF` (background light)
- Dark: `#1A1A1A` (background dark)

**Accent Colors:**
- Success: `#4CAF50`
- Warning: `#FF9800`
- Error: `#F44336`
- Info: `#2196F3`

### Typography

**Fonts:**
- Headlines: **Poppins Bold** or **Inter Bold**
- Body: **Inter Regular** or **Roboto Regular**
- Code: **Fira Code** or **JetBrains Mono**

**Sizes:**
- Main headline: 48-64px
- Subheading: 24-32px
- Body: 16-20px
- Code: 14-16px

### Style Guidelines

**Aesthetic:** Modern, clean, developer-focused

**Do's:**
- ✅ Use real code snippets (syntax highlighted)
- ✅ Show actual screenshots (not mockups)
- ✅ Include performance numbers (when proven)
- ✅ Professional but approachable tone
- ✅ High contrast (readable text)

**Don'ts:**
- ❌ Stock photos or generic graphics
- ❌ Fake data or placeholder text
- ❌ Cluttered layouts
- ❌ Low-quality screenshots
- ❌ Misleading claims without proof

---

## 📐 Asset Specifications by Platform

### Twitter/X

**Profile Picture:** 400 x 400 px (square)
- Your photo or logo
- High resolution

**Header Image:** 1500 x 500 px
- Mentioned above in Required Assets

**In-Tweet Images:**
- Single image: 1200 x 675 px (16:9)
- Multiple images (2): 700 x 800 px each
- Multiple images (3-4): 1200 x 675 px total

### Reddit

**Thumbnail:** Auto-generated from link OR 140 x 140 px
- Usually auto-generated, not critical

**In-Post Images:**
- Optimal: 1200 x 675 px
- Reddit displays images inline

### Dev.to

**Cover Image:** 1000 x 420 px
- Mentioned above in Required Assets
- Critical for article preview

**In-Article Images:**
- Width: 800-1000 px
- Format: PNG (for screenshots), JPG (for photos)
- Add alt text for accessibility

### LinkedIn

**Post Image:** 1200 x 627 px
- Horizontal orientation preferred
- Professional aesthetic

**Article Cover:** 1200 x 627 px
- Same as post image

### GitHub

**Social Preview:** 1280 x 640 px
- Mentioned above in Required Assets
- Shows when repo is shared

**README Images:**
- Width: 600-800 px
- Format: PNG (with transparency if needed)
- Host on GitHub: `doc/images/` directory

---

## 🛠️ Tools & Resources

### Design Tools

**Free:**
- **Canva** (easiest): https://canva.com
  - Templates for all social media sizes
  - Drag-and-drop interface
  - Free stock images and elements

- **Figma** (professional): https://figma.com
  - Free for individual use
  - Collaborative design
  - Vector graphics

- **GIMP** (open source): https://gimp.org
  - Free Photoshop alternative
  - Advanced image editing

**Paid:**
- **Adobe Photoshop**: Industry standard
- **Sketch**: Mac-only, UI design focused
- **Affinity Designer**: One-time purchase

### Screenshot Tools

**macOS:**
- Cmd+Shift+4: Area screenshot
- Cmd+Shift+5: Advanced options
- **CleanShot X** (paid): Professional screenshots

**Windows:**
- Win+Shift+S: Snipping tool
- **ShareX** (free): Advanced screenshots
- **Snagit** (paid): Professional tool

**Linux:**
- **Flameshot** (free): Feature-rich
- **Shutter** (free): Annotation support

**Cross-platform:**
- **Lightshot**: Quick screenshots
- **Monosnap**: Screenshots + video

### Mobile Screenshots

**For App Screenshots:**
1. Run app in simulator/emulator
2. Take screenshot (varies by device)
3. Use device frame (optional)

**Device Frame Tools:**
- **Device Frames** (Figma plugin)
- **AppMockUp**: Device mockups
- **Cleanmock**: Minimal device frames

### Code Screenshot Tools

**For Beautiful Code Snippets:**
- **Carbon** (free): https://carbon.now.sh
  - Syntax highlighting
  - Multiple themes
  - Export PNG/SVG

- **Ray.so** (free): https://ray.so
  - Clean aesthetic
  - Multiple colors

- **CodeSnap** (VS Code extension)
  - Screenshot directly from editor

### Image Optimization

**Before uploading, optimize file sizes:**
- **TinyPNG**: https://tinypng.com (lossy, great quality)
- **ImageOptim** (Mac): Lossless compression
- **Squoosh**: https://squoosh.app (Google, advanced)

**Target file sizes:**
- Twitter: <5 MB
- Dev.to: <25 MB
- LinkedIn: <10 MB

---

## 📋 Asset Creation Checklist

### Before Launch Day

**Required Assets (Must Have):**
- [ ] Twitter header image created
- [ ] Dev.to cover image created
- [ ] GitHub social preview image uploaded
- [ ] Screenshot 1: ChatGPT clone (working example)
- [ ] Screenshot 2: Code example (3-line setup)

**Recommended Assets (Should Have):**
- [ ] Twitter post image (comparison or feature highlights)
- [ ] Screenshot 3: Security warning dialog
- [ ] Screenshot 4: Token usage console output
- [ ] Screenshot 5: Dark mode example
- [ ] LinkedIn post image (professional version)

**Optional Assets (Nice to Have):**
- [ ] Screenshot 6: Performance benchmarks
- [ ] Screenshot 7: Comparison table
- [ ] Short demo video (15-30 seconds)
- [ ] Animated GIF of streaming text
- [ ] Logo/icon for package

### During Launch Day

- [ ] Take screenshots of engagement (for follow-up posts)
- [ ] Screenshot positive comments/testimonials
- [ ] Capture any viral moments
- [ ] Record metrics for post-mortem

### After Launch

- [ ] Update images with star count
- [ ] Create "Featured on" badges if featured anywhere
- [ ] Generate "Thank you" graphics for top contributors
- [ ] Create case study images (user testimonials)

---

## 🎬 Video Content (Optional but Powerful)

### Short Demo Video (15-30 seconds)
**Purpose:** Show package in action
**Platform:** Twitter, LinkedIn, Reddit

**Script:**
1. [0-5s] Show code: 3-line setup
2. [5-10s] Run app, show loading
3. [10-20s] Demo: Type message, see streaming response
4. [20-30s] Highlight features (markdown, code highlighting)
5. [30s] End card: "Try it: pub.dev/packages/flutter_gen_ai_chat_ui"

**Tools:**
- **QuickTime** (Mac): Screen recording
- **OBS Studio** (free, cross-platform): Advanced recording
- **Loom**: Quick screen recordings with webcam

**Editing:**
- **iMovie** (Mac, free): Basic editing
- **DaVinci Resolve** (free): Professional editing
- **CapCut** (free): Mobile + desktop, easy

### Tutorial Video (5-10 minutes)
**Purpose:** Complete setup walkthrough
**Platform:** YouTube, Dev.to

**Outline:**
1. Introduction (1 min)
2. Installation (1 min)
3. Basic setup (2 min)
4. Advanced configuration (3 min)
5. Security best practices (2 min)
6. Wrap up + call to action (1 min)

---

## 🎨 Canva Templates (Quick Start)

**If you use Canva, search for these templates:**

**For Twitter Header:**
- Search: "Twitter header tech"
- Customize with package colors and content

**For Dev.to Cover:**
- Search: "Blog header 1000x420"
- Use code + screenshot template

**For Social Media Posts:**
- Search: "Tech announcement"
- Filter by dimensions (1200x675)

**Pro tip:** Create a "Brand Kit" in Canva with your colors, fonts, and logo for consistency.

---

## 🎯 Priority Action Plan

### If You Have 30 Minutes
**Create these 3 assets:**
1. **GitHub Social Preview** (1280x640) - Most important for sharing
2. **Dev.to Cover Image** (1000x420) - For article
3. **Screenshot: ChatGPT Clone** - Shows working product

### If You Have 1 Hour
**Add these:**
4. **Twitter Header** (1500x500) - Professionalizes your profile
5. **Code Screenshot** - Shows 3-line simplicity
6. **Comparison Image** - Highlights unique value

### If You Have 2 Hours
**Complete package:**
7. All screenshots (dark mode, security, tokens)
8. Twitter post image
9. LinkedIn post image
10. Short demo video (15-30 seconds)

---

## 📏 Quick Reference: Dimensions

```
Platform               | Asset Type        | Dimensions (px)
-----------------------|-------------------|------------------
Twitter                | Header            | 1500 x 500
Twitter                | Post Image        | 1200 x 675
Twitter                | Profile           | 400 x 400
Dev.to                 | Cover             | 1000 x 420
GitHub                 | Social Preview    | 1280 x 640
LinkedIn               | Post Image        | 1200 x 627
Reddit                 | Post Image        | 1200 x 675
Instagram (optional)   | Post              | 1080 x 1080
YouTube (optional)     | Thumbnail         | 1280 x 720
```

---

## ✅ Final Checklist

**Before you start creating:**
- [ ] Have working example app running (for screenshots)
- [ ] Have code editor open with 3-line example
- [ ] Have brand colors saved (`#02569B`, `#10A37F`)
- [ ] Have Canva account (or chosen design tool)

**While creating:**
- [ ] Use high-resolution screenshots (2x or 3x)
- [ ] Ensure text is readable at thumbnail size
- [ ] Check colors are accessible (contrast ratio >4.5:1)
- [ ] Include clear call-to-action

**Before uploading:**
- [ ] Optimize file sizes (<5 MB for Twitter)
- [ ] Preview how it looks at different sizes
- [ ] Double-check spelling and URLs
- [ ] Save source files for future edits

---

## 💡 Pro Tips

1. **Consistency is Key**
   - Use same fonts across all assets
   - Use same color palette
   - Use same style (rounded corners, shadows, etc.)

2. **Text Should Be Readable**
   - Minimum 20px font size for social media
   - High contrast between text and background
   - Avoid busy backgrounds behind text

3. **Show, Don't Tell**
   - Real screenshots > stock graphics
   - Actual code > pseudocode
   - Proven numbers > vague claims

4. **Mobile-First Preview**
   - Most users see posts on mobile
   - Preview images on phone screen
   - Ensure text is still readable when small

5. **A/B Testing**
   - Create 2-3 versions of key images
   - Test which performs better
   - Iterate based on engagement

---

## 📞 Need Help?

**Free Design Resources:**
- Unsplash: Free stock photos
- Pexels: Free stock photos/videos
- Flaticon: Free icons
- Google Fonts: Free fonts

**Communities:**
- r/design_critiques: Get feedback
- Designer News: Design community
- Dribbble: Design inspiration

**Quick Tips:**
- Keep it simple
- Focus on readability
- Show real product
- Be consistent

---

**Last Updated:** 2025-11-06
**Status:** Ready to create assets
**Priority:** Create GitHub Social Preview and Dev.to cover image first

Good luck with your launch! 🚀
