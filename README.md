# My Dotfiles

Take a look at the [setup.sh](./setup.sh) script. 

Or just run it (you should [look at it...](./setup.sh))

```bash
bash setup.sh
```

## GNU `stow`

```bash
brew install stow
```

`stow` creates symlinks to your home directory for you.

```bash
#!/bin/bash

stow -v -R --dotfiles asdf
stow -v -R --dotfiles aws
```

Checkout this article to get started

https://alexpearce.me/2016/02/managing-dotfiles-with-stow/
