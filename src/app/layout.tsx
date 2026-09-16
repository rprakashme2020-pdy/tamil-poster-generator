import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "தமிழ் போஸ்டர் | Tamil Poster Generator",
  description: "Create an approved, personalized Tamil poster for WhatsApp or Instagram.",
  icons: { icon: "/favicon.svg" },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="ta"><body>{children}</body></html>;
}
