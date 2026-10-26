-- Neovim counterpart of .zed/: lazy.nvim loads this as a project-local spec (trust it once when asked).
-- Run a task with <leader>oo, see output with <leader>ow, start debugging with <leader>dc.
local root = vim.fs.dirname(vim.fs.find(".lazy.lua", { upward = true })[1])

-- .zed/settings.json: 4-space C++ (format on save through clangd + .clang-format is already LazyVim's default)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "cpp",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

-- .zed/tasks.json; save = true mirrors Zed's `"save": "all"`
local function shell_task(name, cmd, opts)
  opts = opts or {}
  return {
    name = name,
    condition = { dir = root },
    builder = function()
      if opts.save then
        vim.cmd("silent! wall")
      end
      return {
        name = name,
        cmd = type(cmd) == "function" and cmd() or cmd,
        cwd = root,
        components = {
          "default",
          vim.tbl_extend("force", { "open_output", on_start = "always" }, opts.output or {}),
        },
      }
    end,
  }
end

local tasks = {
  shell_task("build: just build and start", "cmake --build build && ./build/bfspp_app", { save = true }),
  shell_task(
    "debug: build + test",
    "cmake --preset debug && cmake --build --preset debug && ctest --preset debug",
    { save = true }
  ),
  shell_task(
    "gcc: build + test (before push)",
    "cmake --preset gcc && cmake --build --preset gcc && ctest --preset gcc",
    { save = true }
  ),
  shell_task(
    "asan: build + test",
    "cmake --preset asan && cmake --build --preset asan && ctest --preset asan",
    { save = true }
  ),
  shell_task(
    "bench: release",
    "cmake --preset release && cmake --build --preset release"
      .. " && ./build/release/bfspp_bench --benchmark_repetitions=5 --benchmark_report_aggregates_only=true",
    { save = true }
  ),
  -- Zed uses the selected text; here it's the word under the cursor
  shell_task("test: word under cursor", function()
    return "./build/debug/bfspp_tests --gtest_filter=" .. vim.fn.shellescape("*" .. vim.fn.expand("<cword>") .. "*")
  end),
  -- .zed/debug.json build step, run as preLaunchTask below; output only pops up if the build fails
  shell_task(
    "build: debug preset",
    "cmake --build --preset debug",
    { save = true, output = { on_start = "never", on_complete = "failure" } }
  ),
}

return {
  {
    "stevearc/overseer.nvim",
    opts = function()
      for _, task in ipairs(tasks) do
        require("overseer").register_template(task)
      end
    end,
  },

  -- .zed/debug.json
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")
      dap.configurations.cpp = dap.configurations.cpp or {}
      table.insert(dap.configurations.cpp, 1, {
        name = "Debug bfspp_app",
        type = "codelldb",
        request = "launch",
        program = root .. "/build/debug/bfspp_app",
        cwd = root,
        preLaunchTask = "build: debug preset",
      })
    end,
  },
}
