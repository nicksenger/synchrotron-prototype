const { Elm } = require('./Main');

const app = Elm.Main.init({
  node: document.getElementById('elm'),
  flags: [process.env.DATA_PATH, process.env.TITLE]
});

document.body.classList.add('synchrotron__container');

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
);


interface PlaybackCommand {
  path: string;
  time: number;
  rate: number;
}

(new MutationObserver((_mutationsList, observer) => {
  const audio = document.getElementById('audio') as HTMLAudioElement;
  const pageContainer = document.getElementById('page-container');

  if (audio && pageContainer) {
    pageContainer.addEventListener('scroll', reportRelativeHeight);
    app.ports.sendActiveHeight.subscribe((activeHeight: number) => {
      pageContainer.scrollTop = activeHeight * pageContainer.clientWidth;
    });

    app.ports.sendPlayback.subscribe(({ path, time, rate }: PlaybackCommand) => {
      audio.src = path;
      audio.currentTime = time;
      audio.playbackRate = rate;
      audio.play();
    });

    app.ports.sendClipboard.subscribe((copyText: string) => {
      navigator.clipboard.writeText(copyText);
    });

    const anchorId = (new URL(location.href)).searchParams.get("anchor");
    if (anchorId) {
      const matchingAnchor = document.getElementById(anchorId);
      if (matchingAnchor) {
        matchingAnchor.scrollIntoView();
      }
    }

    observer.disconnect();
  }
})).observe(document.body, { childList: true, subtree: true });

window.addEventListener('keydown', (ev: KeyboardEvent) => {
  if (ev.shiftKey) {
    if (ev.keyCode === 80) {
      const audio = document.getElementById('audio') as HTMLAudioElement;
      if (audio) {
        if (audio.paused) {
          audio.play();
        } else {
          audio.pause();
        }
      }
    }
  }
});
