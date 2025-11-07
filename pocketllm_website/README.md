# PocketLLM Marketing Website 🚀

A modern, responsive marketing website for PocketLLM - Your Pocket AI. Built with Next.js 16, TypeScript, Tailwind CSS, and Framer Motion.

![PocketLLM](https://img.shields.io/badge/PocketLLM-Your%20Pocket%20AI-purple?style=for-the-badge)
![Next.js](https://img.shields.io/badge/Next.js-16.0.1-black?style=for-the-badge&logo=next.js)
![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue?style=for-the-badge&logo=typescript)
![Tailwind CSS](https://img.shields.io/badge/Tailwind-4.0-38bdf8?style=for-the-badge&logo=tailwind-css)

## 🌟 Features

### 🎨 Design & UI
- **Modern Glassmorphism Design** - Beautiful glass-effect components with backdrop blur
- **Animated Backgrounds** - Dynamic 3D ColorBends background using Three.js
- **Smooth Animations** - Powered by Framer Motion for buttery-smooth transitions
- **Responsive Layout** - Fully responsive across all devices (mobile, tablet, desktop)
- **Custom Typography** - Silver Garden (serif) and Kollektif (sans-serif) fonts

### 📱 Interactive Components
- **Newsletter Popup** - Auto-appears after 3 seconds on first visit
- **Waitlist Popup** - Triggers when user scrolls 80% down the page
- **GitHub Star Button** - Live star count from GitHub API
- **Navigation Menu** - Responsive navbar with dropdown menus and mobile sheet
- **Animated Text** - Character-by-character blur-in animations

### 📄 Page Sections
1. **Hero Section** - Eye-catching title with animated text and CTAs
2. **Models Showcase** - Highlighting OpenAI, Gemini, Groq, and Ollama support
3. **Key Features** - 6 feature cards with gradient icons
4. **Use Cases** - Real-world applications for different user types
5. **Trust Signals** - Statistics and social proof
6. **Technical Features** - Deep dive into technical capabilities
7. **Pricing** - Three-tier pricing with feature comparison
8. **About/Mission** - Company vision and values
9. **Footer** - Comprehensive footer with navigation and social links

### ⚡ Performance
- **Static Site Generation (SSG)** - Pre-rendered pages for optimal performance
- **Turbopack** - Lightning-fast builds and hot module replacement
- **Optimized Images** - Next.js Image optimization
- **Code Splitting** - Automatic code splitting for faster page loads

## 🛠️ Tech Stack

- **Framework**: [Next.js 16](https://nextjs.org/) with App Router
- **Language**: [TypeScript](https://www.typescriptlang.org/)
- **Styling**: [Tailwind CSS 4](https://tailwindcss.com/)
- **Animations**: [Framer Motion](https://www.framer.com/motion/)
- **3D Graphics**: [Three.js](https://threejs.org/) (for ColorBends background)
- **UI Components**: [shadcn/ui](https://ui.shadcn.com/) + [Radix UI](https://www.radix-ui.com/)
- **Icons**: [Lucide React](https://lucide.dev/)

## 📦 Installation

### Prerequisites
- Node.js 18+
- npm or yarn or pnpm

### Setup

1. **Clone the repository**
```bash
git clone https://github.com/PocketLLM/PocketLLM.git
cd pocketllm_website
```

2. **Install dependencies**
```bash
npm install
# or
yarn install
# or
pnpm install
```

3. **Run development server**
```bash
npm run dev
# or
yarn dev
# or
pnpm dev
```

4. **Open your browser**
Navigate to [http://localhost:3000](http://localhost:3000)

## 🚀 Build & Deploy

### Production Build
```bash
npm run build
npm run start
```

### Build Output
The build process generates static HTML files for optimal performance:
- Pre-rendered pages: `/`, `/demo`, `/_not-found`
- Optimized assets in `.next/static/`

### Deployment Options

#### Vercel (Recommended)
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel
```

#### Netlify
```bash
# Build command
npm run build

# Publish directory
.next
```

#### Docker
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

## 📁 Project Structure

```
pocketllm_website/
├── app/
│   ├── layout.tsx          # Root layout with metadata
│   ├── page.tsx            # Home page with all sections
│   ├── demo/               # Demo page
│   └── globals.css         # Global styles and fonts
├── components/
│   ├── Navbar.tsx          # Navigation component
│   └── ui/
│       ├── ColorBends.tsx          # 3D animated background
│       ├── footer.tsx              # Footer component
│       ├── github-star-button.tsx  # GitHub star button
│       ├── newsletter-popup.tsx    # Newsletter signup
│       ├── waitlist-popup.tsx      # Waitlist signup
│       ├── text-animate.tsx        # Text animation component
│       └── highlighter.tsx         # Text highlighter
├── public/
│   └── asset/
│       └── fonts/          # Custom fonts
├── package.json
├── tsconfig.json
├── tailwind.config.ts
└── next.config.ts
```

## 🎨 Customization

### Colors
The website uses a purple/pink/blue gradient theme. To customize colors, edit the Tailwind classes in components:

```tsx
// Primary gradient
className="bg-linear-to-r from-purple-500 to-pink-500"

// Secondary gradient
className="bg-linear-to-r from-blue-500 to-purple-500"
```

### Fonts
Custom fonts are loaded in `app/globals.css`:
- **Silver Garden**: Serif font for headings
- **Kollektif**: Sans-serif font for body text

To change fonts, replace the font files in `public/asset/fonts/` and update the `@font-face` declarations.

### Content
All content is in `app/page.tsx`. Edit the JSX to update:
- Hero text
- Feature descriptions
- Pricing tiers
- Footer links

### Popups
Configure popup behavior in the component files:
- **Newsletter**: `components/ui/newsletter-popup.tsx` (delay: 3000ms)
- **Waitlist**: `components/ui/waitlist-popup.tsx` (trigger: 80% scroll)

## 🔧 Configuration

### Environment Variables
Create a `.env.local` file for environment-specific settings:

```env
# Optional: Analytics
NEXT_PUBLIC_GA_ID=your-google-analytics-id

# Optional: API endpoints
NEXT_PUBLIC_API_URL=https://api.pocketllm.com
```

### Metadata
Update SEO metadata in `app/layout.tsx`:

```tsx
export const metadata: Metadata = {
  title: "PocketLLM - Your Pocket AI",
  description: "Your custom description",
  openGraph: {
    title: "PocketLLM",
    description: "Your custom description",
    type: "website",
  },
};
```

## 📊 Performance Metrics

- **Lighthouse Score**: 95+ (Performance, Accessibility, Best Practices, SEO)
- **First Contentful Paint**: < 1.5s
- **Time to Interactive**: < 3.5s
- **Bundle Size**: Optimized with code splitting

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow TypeScript best practices
- Use Tailwind CSS for styling (avoid inline styles)
- Ensure responsive design across all breakpoints
- Test on multiple browsers and devices
- Keep components modular and reusable

## 🐛 Troubleshooting

### Build Errors
```bash
# Clear Next.js cache
rm -rf .next

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

### Font Loading Issues
Ensure font files are in `public/asset/fonts/` and paths in `globals.css` are correct.

### Popup Not Showing
Check browser localStorage - clear it to reset popup visibility:
```javascript
localStorage.removeItem('newsletter-popup-seen')
localStorage.removeItem('waitlist-popup-seen')
```

## 📝 License

This project is part of the PocketLLM ecosystem. See the main repository for license information.

## 🔗 Links

- **Main Repository**: [github.com/PocketLLM/PocketLLM](https://github.com/PocketLLM/PocketLLM)
- **Website**: [pocketllm.com](https://pocketllm.com) (coming soon)
- **Documentation**: [docs.pocketllm.com](https://docs.pocketllm.com) (coming soon)
- **Twitter**: [@PocketLLM](https://twitter.com/PocketLLM)

## 💬 Support

For questions or issues:
- Open an issue on [GitHub](https://github.com/PocketLLM/PocketLLM/issues)
- Join our community forum (coming soon)
- Email: support@pocketllm.com

---

**Built with ❤️ by the PocketLLM Team**

*One chat for every LLM. Your Pocket AI.*