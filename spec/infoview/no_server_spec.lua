local fixtures = require 'spec.fixtures'
local wait = require('spec.helpers').wait

vim.g.lean_config =
  vim.tbl_deep_extend('force', vim.g.lean_config, { progress_bars = { enable = false } })

describe('no language server', function()
  it('is shown when the server fails to start', function()
    local path = vim.env.PATH
    vim.env.PATH = ''
    vim.cmd.edit { fixtures.example:child 'Example/Squares.lean' }

    wait:for_infoview_contents '^⚠ The Lean language server failed to start: .*"lake", "serve"'
    vim.env.PATH = path

    -- and comes back once it can start
    vim.cmd.edit()
    wait:for_infoview_contents 'information'
    assert.infoview_contents.are [[
      ▼ 1:1-1:6: information:
      1
    ]]
  end)

  it('is shown when the server is not enabled', function()
    vim.lsp.enable('leanls', false)
    vim.cmd.edit { fixtures.example:child 'foo/Foo.lean' }

    wait:for_infoview_contents 'not enabled'
    assert.infoview_contents_nowait.are '⚠ The Lean language server (leanls) is not enabled.'
    vim.lsp.enable 'leanls'
  end)
end)
