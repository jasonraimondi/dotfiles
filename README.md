```md
  _____   ____ _______ ______ _____ _      ______  _____ 
 |  __ \ / __ \__   __|  ____|_   _| |    |  ____|/ ____|
 | |  | | |  | | | |  | |__    | | | |    | |__  | (___  
 | |  | | |  | | | |  |  __|   | | | |    |  __|  \___ \ 
 | |__| | |__| | | |  | |     _| |_| |____| |____ ____) |
 |_____/ \____/  |_|  |_|    |_____|______|______|_____/ 


 asdf         > asdf for maintaining language versions
 aws          > amazon is taking over the world
 bin          > custom bin scripts
 brew         > homebrew all the things
 config       > for the .config
 dictionary   > extend the macos dictionary
 git          > global git config and aliases
 iterm2       > iterm2 scripts
 mackup       > application settings sync 
 ssh          > ssh config
 tmux         > tmux config
 ubersicht    > ubersicht widgets
 vim          > vim configs
 zsh          > shell configuration 🔥🔥

```

## Usage

Take a look at the [setup.sh](./setup.sh) script to see how to put everything all together. 

```bash
bash setup.sh
```

## Stow

[GNU stow](https://www.gnu.org/software/stow/), or just `stow`, manages symbolic links from your dotfiles directory to the home directory. To get stow on MacOS, use [homebrew](https://brew.sh/).

```bash
brew install stow
```

We are utilizing the `--dotfiles` flag. This allows us to have folders with `dot-example` that will convert to `.example`. The following is from the stow manpage.

```
 --dotfiles

   Enable special handling for "dotfiles" (files or folders whose name
   begins with a period) in the package directory. If this option is
   enabled, Stow will add a preprocessing step for each file or folder
   whose name begins with "dot-", and replace the "dot-" prefix in the
   name by a period (.). This is useful when Stow is used to manage
   collections of dotfiles, to avoid having a package directory full of
   hidden files.

   For example, suppose we have a package containing two files,
   stow/dot-bashrc and stow/dot-emacs.d/init.el. With this option, Stow
   will create symlinks from .bashrc to stow/dot-bashrc and from
   .emacs.d/init.el to stow/dot-emacs.d/init.el. Any other files, whose
   name does not begin with "dot-", will be processed as usual.
```

Checkout this article for a more detailed explanation on using stow https://alexpearce.me/2016/02/managing-dotfiles-with-stow/

## zsh

The [~/.zshrc](zsh/dot-zshrc) imports our main entrypoint.

```bash
source "${HOME}/.zsh/_main.zsh"
```

The [~/.zsh/_main.zsh](zsh/dot-zsh/_main.zsh) file globs all zsh files in the `zsh/dot-zsh/*.zsh` directory and loads them.

All file ending in `*.zsh` in the [~/.zsh](macos/zsh/dot-zsh) directory will be sourced.

### Prezto — Instantly Awesome Zsh

[Prezto](https://github.com/sorin-ionescu/prezto) is the chosen included zsh framework.

```bash
cd dotfiles

# The following is included in the setup script
git submodule update --init --recursive
stow -v -R --dotfiles zsh
```

## Brewfile

The [Brewfile](./Brewfile)

https://thoughtbot.com/blog/brewfile-a-gemfile-but-for-homebrew

```bash
cd dotfiles
brew bundle
```

## Misc

Ascii art generated using https://www.coolgenerator.com/ascii-text-generator with **big** font
