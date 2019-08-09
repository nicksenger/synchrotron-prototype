const { Elm } = require('./Main');

Elm.Main.init({
  node: document.getElementById('elm'),
  flags: null
});

document.body.classList.add('fsi__container');
