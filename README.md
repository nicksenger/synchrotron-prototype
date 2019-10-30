# Synchrotron

Synchrotron is a progressive web app which sychronizes audio files to text. Examples at https://fsi.nsenger.com and https://dli.nsenger.com.

## Commands

```sh
npm test # runs the tests
npm run watch # runs the app in watch mode
npm run build --title APP_TITLE --datapath PATH_TO_DATA_DIRECTORY # builds the app
```

To build a Synchrotron app, you must specify a path (`--datapath`) relative to `index.html` containing a `data.json` used to determine the relationship between images, audio, bookmarks and anchors. The `data.json` for your project should have the following format:

```ts
{
  pages: Array<{ // array of data for pages to be shown
    number: number // the page number
    path: string // the path to the image for the page (relative to index.html)
    aspectRatio: number // the aspect ratio of the page (height / width)
    height: number // the sum of aspect ratios from all preceding pages
    anchors: Array<{ // list of anchors for the page
      id: string // a unique identifier differentiating the anchor from others on the page
      track: number // the index of the audio track that the anchor links to
      time: number // the time in seconds of the track that the anchor links to
      top: number // percentage height from the top of the page to position the anchor
      left: number // percentage height from the left of the page to position the anchor
    }>
  }>
  bookmarks: Array<{ // data for bookmarks linking to specific pages
    title: string // title of the bookmark to display in the bookmarks menu
    page: number // page number that the bookmark links to
  }>
  tracks: Array<{ // data for audio tracks
    number: number // the track number
    title: string // the title of the track
    path: string // the path the the audio file (relative to index.html)
  }>
}
```
