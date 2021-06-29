# Moon Garden

A simple digital garden / second brain, powered by [Fission's Webnative SDK](https://github.com/fission-suite/webnative). Includes `[[wikilinks]]` for linking to other pages.

## Development

### Nix

Setup / dependencies all managed by [nix](https://nixos.org/guides/install-nix.html):

```
nix-shell
yarn install
```

Development server (inside the nix-shell)

```
yarn start
```

### Manual

* Install [Node](https://nodejs.org/en/) 16.x
* Install [Yarn](https://yarnpkg.com/) 1.22.x
