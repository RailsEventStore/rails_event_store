import { CountUp } from 'countup.js';

const countMeUp = (target, count) => {
  let countUp = new CountUp(target, count);
  countUp.start();
};

window.onload = () => {
  document.querySelectorAll('[data-count]').forEach((element) => countMeUp(element, element.dataset.count));
};
