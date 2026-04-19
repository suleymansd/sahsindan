import "./globals.css";

import type { Metadata, Viewport } from "next";
import { Manrope, Sora } from "next/font/google";

import { ThemeProvider } from "@/components/theme-provider";
import { Providers } from "@/components/providers";

const sans = Manrope({
  subsets: ["latin", "latin-ext"],
  display: "swap",
  variable: "--font-manrope",
  weight: ["400", "500", "600", "700", "800"],
});

const display = Sora({
  subsets: ["latin", "latin-ext"],
  display: "swap",
  variable: "--font-sora",
  weight: ["500", "600", "700", "800"],
});

export const metadata: Metadata = {
  title: "şahsından.com · Doğrulanmış kapalı araç pazarı",
  description:
    "Kimliği doğrulanmış üyeler arasında güvenli alım-satım. Net iletişim, planlı randevu, taze ilanlar.",
  applicationName: "şahsından.com",
  authors: [{ name: "şahsından.com" }],
  icons: {
    icon: "/favicon.ico",
  },
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#F3F8FF" },
    { media: "(prefers-color-scheme: dark)", color: "#071426" },
  ],
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="tr" suppressHydrationWarning className={`${sans.variable} ${display.variable}`}>
      <body className="font-sans">
        <ThemeProvider attribute="class" defaultTheme="light" enableSystem>
          <Providers>{children}</Providers>
        </ThemeProvider>
      </body>
    </html>
  );
}
