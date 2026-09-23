return {
  {
    "snacks.nvim",
    opts = function(_, opts)
      local keys = opts.dashboard and opts.dashboard.preset and opts.dashboard.preset.keys
      if not keys then
        return
      end

      table.insert(keys, {
        icon = "󰙅 ",
        key = "e",
        desc = "Explore Files",
        action = function()
          vim.cmd("Neotree reveal left")
        end,
      })
    end,
  },
}
