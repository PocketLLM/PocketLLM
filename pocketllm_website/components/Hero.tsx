import { TextAnimate } from "./ui/text-animate";
import { Highlighter } from "./ui/highlighter";

const Hero = () => {
  return (
    <section className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pt-20 text-center">
      <h1 className="text-4xl font-extrabold tracking-tight lg:text-5xl">
        <TextAnimate
          styledWords={{
            PocketLLM: "font-silverGarden text-[#E6E6FA]",
          }}
        >
          PocketLLM — Your pocket AI. One chat for every LLM.
        </TextAnimate>
      </h1>
      <p className="mt-6 text-lg leading-8 text-gray-300">
        <Highlighter>
          Connect OpenAI, Gemini, Groq, and more. Manage conversations, switch
          models instantly, and carry serious AI power in one app. Built with
          Flutter for fast, cross-platform delivery.
        </Highlighter>
      </p>
      <div className="mt-10 flex items-center justify-center gap-x-6">
        <a
          href="#"
          className="rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        >
          Get Started Free
        </a>
        <a href="#" className="text-sm font-semibold leading-6 text-white">
          Download Now <span aria-hidden="true">→</span>
        </a>
      </div>
    </section>
  );
};

export default Hero;