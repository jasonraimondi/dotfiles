# Jason's Dotfiles

Maintaining your machine's configs in git is :fire:

## Usage

Take a look at the [setup.sh](./setup.sh) script and give it a run.

```bash
bash setup.sh
```

## GNU stow

[GNU stow](https://www.gnu.org/software/stow/), or just `stow`, is a symbolic link manager. When using with dotfiles, stow maintains symlinks from your dotfiles directory, to the home directory for you.

To get stow on MacOS, first you need [Homebrew](https://brew.sh/).

```bash
brew install stow
```

Checkout this article to get started: https://alexpearce.me/2016/02/managing-dotfiles-with-stow/

## zsh

Our [~/.zshrc](zsh/dot-zshrc#L11) starts the main import.

### Prezto — Instantly Awesome Zsh

[Prezto](https://github.com/sorin-ionescu/prezto) is included as a submodule and can be installed/upgraded:

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
