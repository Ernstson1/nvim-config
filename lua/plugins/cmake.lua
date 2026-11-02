return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cmake = { "gersemi" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "gersemi" } },
  },
}
