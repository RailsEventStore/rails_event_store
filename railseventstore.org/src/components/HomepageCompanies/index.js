const CompaniesList = [
  {
    name: "billetto",
    img: "/images/billetto_logo.svg",
    link: "https://billetto.co.uk",
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
];

function Company({ name, img, link }) {
  return (
    <li>
      <a className="grid h-full px-4 py-6 text-center rounded-lg place-content-center hover:bg-gray-100 bg-gray-50 min-h-36" href={link}>
        <img className="w-full max-w-40" src={img} alt={name} />
      </a>
    </li>
  );
}

export default function HomepageCompanies() {
  return (
    <section className="mb-20">
      <header className="container mb-8 text-center">
        <h2 className="text-xl">
          Join growing list of companies using Rails Event Store
        </h2>
      </header>
      <ul className="container grid grid-cols-1 gap-4 list-none sm:grid-cols-2 lg:grid-cols-4">
        {CompaniesList.map((props, idx) => (
          <Company key={idx} {...props} />
        ))}
      </ul>
    </section>
  );
}
