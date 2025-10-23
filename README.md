# RatDotRaw's dotfiles

A repo to store my dotfiles and Arch Linux bootstrapper script.

## Installation

> [!CAUTION]
> If you want to try out these dotfiles, you should fork the project, review the code and make changes to fit your needs.

### Base Arch Linux Install Using `base_isntall.sh`

> [!IMPORTANT]
> `base_install.sh` is written for Arch Linux (derivative) distributions. **It will not work for any other distro's**.

The repo includes a `base_install.sh` script, which when executed, will install all packages and some basic configuration.

After running the script, you will be left with a **very basic** version of **my preferred Arch Linux** installation.

1. Clone or download the repository and navigate inside it.
2. Grand `base_install.sh` execute permission using `chmod +x base_install.sh`
3. Execute the script using Bash `Bash ./base_install.sh`

### Installing the Dotfiles Using `linker.sh`

> [!NOTE]
> The `linker.sh` will link all dotfiles to their respective directory.
> Editing the files in the repo will also change config files itself.

1. Clone or download the repository and navigate inside it.
2. Grand `linker.sh` execute permission using `chmod +x linker.sh`
3. Execute the script using Bash `Bash ./linker.sh`

## Feedback

Suggestions and improvements are always welcome!
Feel free to open an issue or a Pull request.