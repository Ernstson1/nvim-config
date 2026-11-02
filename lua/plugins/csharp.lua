return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        exclude = { "cs" },
      },
    },
  },
  {
    "GustavEikaas/easy-dotnet.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
    ft = { "cs", "fsharp", "vb", "xml", "sln", "csproj", "fsproj" },
    cmd = "Dotnet",
    opts = {
      -- The dotnet extra already runs omnisharp; easy-dotnet's Roslyn server would duplicate it
      lsp = { enabled = false },
      -- Defaults are single-key <leader>r/d/t/p in test files, clashing with LazyVim groups and the <leader>t terminals
      test_runner = {
        mappings = {
          run_test_from_buffer = { lhs = "<leader>Tr", desc = "Run test" },
          debug_test_from_buffer = { lhs = "<leader>Td", desc = "Debug test" },
          run_all_tests_from_buffer = { lhs = "<leader>Tt", desc = "Run all tests in file" },
          peek_stack_trace_from_buffer = { lhs = "<leader>Tp", desc = "Peek test output" },
        },
      },
    },
  },
}
