import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "PLANGO — Your AI productivity workspace",
  description: "An intelligent personal and organization workspace for tasks, teams, email, customers, documents and files.",
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
