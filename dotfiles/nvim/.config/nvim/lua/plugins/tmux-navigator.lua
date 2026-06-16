return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>",  desc = "Window left  (tmux-aware)" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>",  desc = "Window down  (tmux-aware)" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>",    desc = "Window up    (tmux-aware)" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Window right (tmux-aware)" },
    },
  },
}
