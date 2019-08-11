const webpack = require('webpack');
const path = require('path');
const argv = require('yargs').argv

module.exports = {
    entry: {
        bundle: ['./src/index.ts', './src/styles.scss'],
        sw: './src/sw.ts'
    },
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: '[name].js',
    },

    devtool: 'source-map',

    resolve: {
        extensions: ['.elm', '.scss', '.ts']
    },

    module: {
        rules: [
            { test: /\.ts$/, loader: 'ts-loader' },
            { test: /\.js$/, loader: 'source-map-loader', enforce: 'pre' },
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: {
                    loader: 'elm-webpack-loader',
                    options: {}
                }
            },
            {
                test: /\.scss$/,
                use: [
                    {
                        loader: 'file-loader',
                        options: {
                            name: 'bundle.css',
                        }
                    },
                    { loader: 'extract-loader' },
                    { loader: 'css-loader' },
                    { loader: 'postcss-loader' },
                    { loader: 'sass-loader' }
                ]
            }
        ]
    },

    plugins: [
        new webpack.DefinePlugin({
            'process.env': JSON.stringify({
                DATA_PATH: argv.datapath,
                TITLE: argv.title
            })
        })
    ]
};
