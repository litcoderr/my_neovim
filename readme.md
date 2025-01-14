# Neovim Setup for UNIX

## Procedure

1. Install Neovim

- mac

    ```bash
    brew install neovim
    ```

- linux

    ```bash
    sudo apt-get install neovim
    ```

2. Pull Repository

```bash
git clone https://github.com/litcoderr/my_neovim
```

3. Install Dependency

- Packer

```bash
git clone --depth 1 https://github.com/wbthomason/packer.nvim \
  ~/.local/share/nvim/site/pack/packer/start/packer.nvim
```

```
:PackerSync
```

- ruff (for Python)

```bash
pip install ruff
```
