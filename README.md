# Jason's Dotfiles

Maintaining your machine's configs in git is :fire:

## Usage

Take a look at the [setup.sh](./setup.sh) script and give it a run.

```bash
bash setup.sh
```

## GNU stow

[GNU stow](https://www.gnu.org/software/stow/), or just `stow`, manages symbolic links from your dotfiles directory to the home directory.

To get stow on MacOS, use [homebrew](https://brew.sh/).

```bash
brew install stow
```

Checkout this article for a more detailed explanation on using stow https://alexpearce.me/2016/02/managing-dotfiles-with-stow/

## zsh

The [~/.zshrc](zsh/dot-zshrc) imports our main entrypoint.

```bash
source "${HOME}/.zsh/_main.zsh"
```

The [~/.zsh/_main.zsh](zsh/dot-zsh/_main.zsh) file globs all zsh files in the `zsh/dot-zsh/*.zsh` directory and loads them.

### Prezto — Instantly Awesome Zsh

[Prezto](https://github.com/sorin-ionescu/prezto) is the chosen included zsh framework.

```bash
cd dotfiles

# The following is included in the setup script
git submodule update --init --recursive
stow -v -R --dotfiles zsh
```

### Custom .zsh files

The main entrypoint for our custom .zsh files is [~/.zsh/_main.zsh](zsh/dot-zsh/_main.zsh).

## Brewfile

The [Brewfile](./Brewfile)

https://thoughtbot.com/blog/brewfile-a-gemfile-but-for-homebrew

```bash
cd dotfiles
brew bundle
```

## Misc

Ascii art generated using https://www.coolgenerator.com/ascii-text-generator with **banner** font
