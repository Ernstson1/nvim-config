return {
  "stevearc/conform.nvim",
  opts = {
    formatters = {
      -- Wrap prose at prettier's default 80 columns, matching markdownlint's MD013
      prettier = { prepend_args = { "--prose-wrap", "always" } },
    },
  },
}
