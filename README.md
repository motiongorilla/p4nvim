# p4nvim - Neovim Perforce Plugin
This Neovim plugin provides a set of commands to interact with Perforce directly from Neovim.

## Installation

You can install this plugin using your preferred plugin manager. Here are examples for some popular ones:

### Using lazy.nvim
```
'motiongorilla/p4nvim',
```

### Using vim-plug
```
Plug 'motiongorilla/p4nvim'
```

### Using packer.nvim
```
use 'motiongorilla/p4nvim'
```
## Prerequisites

Neovim 0.5 or higher
Perforce client installed and configured
Telescope.nvim (if you want to see checkout files in Telescope)

## Important Note

The plugin gathers user data on Neovim start using the p4 info command. Ensure that p4 info provides correct results for the plugin to function properly.

## Commands

The plugin creates the following user commands when Neovim starts:
**:P4Checkout** - Checkout and add a file for editing.
**:P4Add** - Add a file to Perforce.
**:P4Revert** - Revert a file.
**:P4MoveRename** - Move or rename a file.
**:P4GetFileCL** - Get the changelist of a file.
**:P4ShowFileHistory** - Show the history of a file.
**:P4MoveToChangelist** - Move a file to another changelist.
**:P4DeleteChangelist** - Delete a changelist.
**:P4ShowCheckedOut** - Show checked out files.
**:P4CheckedInTelescope** - Show checked out files in Telescope.
**:P4CLList** - Show the list of changelists.

## Key Mappings

You can set key mappings for these commands in your init.vim or init.lua. Here are some examples:

### Example for init.vim
```
nnoremap <leader>pc :P4Checkout<CR>
nnoremap <leader>pa :P4Add<CR>
nnoremap <leader>pr :P4Revert<CR>
nnoremap <leader>pm :P4MoveRename<CR>
nnoremap <leader>pg :P4GetFileCL<CR>
nnoremap <leader>ph :P4ShowFileHistory<CR>
nnoremap <leader>pl :P4MoveToChangelist<CR>
nnoremap <leader>pd :P4DeleteChangelist<CR>
nnoremap <leader>ps :P4ShowCheckedOut<CR>
nnoremap <leader>pt :P4CheckedInTelescope<CR>
nnoremap <leader>pc :P4CLList<CR>
```

### Example for init.lua
```
vim.keymap.set("n", "<leader>p4a", ":P4Add<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>p4e", ":P4Checkout<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>p4r", ":P4Revert<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>p4t", ":P4CheckedInTelescope<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<leader>pm', ':P4MoveRename<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>pg', ':P4GetFileCL<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ph', ':P4ShowFileHistory<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>pl', ':P4MoveToChangelist<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>pd', ':P4DeleteChangelist<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ps', ':P4ShowCheckedOut<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>pc', ':P4CLList<CR>', { noremap = true, silent = true })
```

## Examples

### Checking Out a File
1. Open the file that you want to check out.
2. Call the command :P4Checkout or use your preferred keymap.
3. Select a changelist (CL) in the window.
4. Press Enter.
5. There's an option to create a new CL. You can create a new CL, and the file will be added to that CL.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## License

This project is licensed under the MIT License.

## Troubleshooting

If you encounter any issues, please check the following:
* Ensure p4 info returns correct results.
* Verify that your Perforce client is properly configured.
