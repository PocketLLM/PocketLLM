import StickyFooter from "@/components/ui/footer";

export default function DemoPage() {
  return (
    <main className="bg-background text-foreground">
      {/* Main Content */}
      <div className="h-screen flex text-[4vw] md:text-[2vw] items-center justify-center bg-gradient-to-br from-background via-muted to-background px-4">
        <div className="text-center">
          <h2 className="leading-none font-serif text-transparent bg-clip-text bg-gradient-to-r from-foreground via-muted-foreground to-foreground/60 mb-6">
            This is an example of a sticky footer
          </h2>
          <div className="w-16 md:w-24 h-0.5 bg-gradient-to-r from-primary to-secondary mx-auto"></div>
        </div>
      </div>

      <StickyFooter />
    </main>
  );
}