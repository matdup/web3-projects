// app/layout.js
import './globals.css';
import Header from "./components/Header";

export const metadata = {
  title: "SecureVault",
  description: "SecureVault DApp",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body className="bg-gray-100 dark:bg-gray-900 text-gray-900 dark:text-gray-100 min-h-screen transition-colors duration-300">
        <Header /> {/* ✅ Composant client */}
        <main className="flex justify-center py-10">
          <div className="w-full max-w-5xl px-6">{children}</div>
        </main>
      </body>
    </html>
  );
}