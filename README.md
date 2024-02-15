# dcu2pas

Decompile dcu(Delphi Compiled Unit) to pas.

## install

Download latest release from [Releases](https://github.com/soarowl/dcu2pas-nim/releases)

## builf from source

```sh
git clone https://github.com/soarowl/dcu2pas-d.git
cd dcu2pas-d
dub build -b release
# or below
dub build -b release --compiler=ldc2
```

## usage

```sh
# short help
dcu2pas -h
# long help
dcu2pas --helps
# decompile a dcu file to pas
dcu2pas abc.dcu
# decompile more dcu files to pas
dcu2pas abc.dcu xyz.dcu
# decompile glob files to pas
dcu2pas abc*.dcu
# decompile all subdirectories' dcu to pas
dcu2pas src/**/*.dcu
```

## colorful output

### linux

Move `config` to `$HOME/.config/cligen`

### windows

Move `config` to `$APPDATA\.config\cligen`

## License

MIT
