const { Elm } = require('./Main');

const app = Elm.Main.init({
  node: document.getElementById('elm'),
  flags: null
});

document.body.classList.add('fsi__container');

const debounce = <F extends (...params: any[]) => void>(fn: F, delay: number) => {
  let timeoutID: number | undefined = undefined;
  return function(this: any, ...args: any[]) {
    clearTimeout(timeoutID);
    timeoutID = window.setTimeout(() => fn.apply(this, args), delay);
  } as F;
}

const reportRelativeHeight = debounce(
  (e: Event) => {
    const target = e.target as HTMLElement;
    const relativeHeight = target.scrollTop / target.clientWidth;
    app.ports.receiveScrollData.send(relativeHeight);
  },
  200
)

setTimeout(() => {
  const pageContainer = document.getElementById('page-container');
  if (pageContainer) {
    pageContainer.addEventListener('scroll', reportRelativeHeight);
  }
}, 200);
