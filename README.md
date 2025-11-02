# :ramen: 📁 ⬆️ miso-fileupload

This fork of [miso-filereader](https://github.com/haskell-miso/miso-filereader)
connects to a Servant server that receives file uploads.

For the development setup, see the [develop branch](https://github.com/MiksuR/miso-fileupload/tree/develop).

# Building
Building the project requires [Nix Flakes](https://nixos.wiki/wiki/Flakes).

After installing Nix and enabling flakes, first enter a devshell by typing

```
nix develop
```

The project can be built and served using `make`:

```
make
make serve
```
