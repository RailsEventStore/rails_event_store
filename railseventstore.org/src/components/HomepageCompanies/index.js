const CompaniesList = [
  {
    name: "billetto",
    img: "/images/billetto_logo.svg",
    link: "https://billetto.dk",
  },
  {
    name: "zencargo",
    img: "/images/zencargo_logo.png",
    link: "https://zencargo.com",
  },
  {
    name: "acatus",
    img: "/images/acatus_logo.svg",
    link: "https://acatus.com",
  },
  {
    name: "assist-software",
    img: "/images/assist_logo.png",
    link: "https://assist-software.net",
  },
  {
    name: "gat",
    img: "/images/gat-logo.svg",
    link: "https://gat.engineering",
  },
  {
    name: "monterail",
    img: "/images/monterail.svg",
    link: "https://www.monterail.com",
  },
  {
    name: "trezy",
    img: "/images/trezy.svg",
    link: "https://www.trezy.io",
  },
  {
    name: "yago",
    img: "/images/yago.svg",
    link: "https://www.yago.be/",
  },
  {
    name: "jobvalley",
    img: "/images/jobvalley.svg",
    link: "https://jobvalley.com/",
  },
  {
    name: "anentawaste",
    img: "/images/anenta.png",
    link: "https://anentawaste.com",
  },
];

function Company({ name, img, link }) {
  return (
    <li>
      <a
        className="grid h-full px-4 py-6 text-center bg-white place-content-center min-h-36"
        href={link}
      >
        <img className="w-full max-w-40" src={img} alt={name} />
      </a>
    </li>
  );
}

export default function HomepageCompanies() {
  return (

    <section className="container my-20 md:mb-32">
      <header className="my-12 text-center ">
        <h2 className="text-2xl font-semibold tracking-tight md:text-3xl">
          Join growing list of companies using Rails Event Store
        </h2>
      </header>
      <ul className="grid grid-cols-1  gap-[1px]  rounded-xl ring-[#141414]/10 bg-[#141414]/10 ring-1 overflow-hidden list-none sm:grid-cols-2 lg:grid-cols-5">
        {CompaniesList.map((props, idx) => (
          <Company key={idx} {...props} />
        ))}
      </ul>

      <div className="flex justify-center mt-12">
          <a href="/billetto" class="!text-white !no-underline relative rounded-full bg-[#141414] dark:bg-white/10 px-4 py-1.5 ">
            {" "}
            See how <span className="font-semibold">Rails Event Store</span> helped <span className="font-semibold">Billetto</span> scale and optimize their
            system!<span aria-hidden="true" className="inline-block ml-2">&rarr;</span>
          </a>
      </div>
    </section>
  );
}
