import "./globals.css";
import { ForgeQueryProvider } from "@/components/query-provider";

export const metadata = {
  title: "Forge",
  description: "Local Qwen coding + research operator console",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body>
        <ForgeQueryProvider>{children}</ForgeQueryProvider>
      </body>
    </html>
  );
}
