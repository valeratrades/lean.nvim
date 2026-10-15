local helpers = require 'spec.helpers'
local infoview = require 'lean.infoview'
local progress = require 'lean.progress'

local CONTENTS = [[
  #eval IO.sleep 3000
  example : 2 = 2 := by
    skip
    rfl
]]

local GOAL = [[
  Goals accomplished 🎉

  ⊢ 2 = 2
]]

---Make Lean reprocess everything, including the cursor position.
local function reprocess()
  vim.api.nvim_buf_set_lines(0, 0, 1, false, { '#eval IO.sleep 3001' })
  local params = vim.lsp.util.make_position_params(0, 'utf-16')
  assert.is_true(vim.wait(10000, function()
    return progress.at(params) == progress.Kind.processing
  end))
end

describe('keep_stale_goal', function()
  after_each(function()
    vim.g.lean_config = nil
  end)

  it(
    'keeps the goal of the same file while Lean processes',
    helpers.clean_buffer(CONTENTS, function()
      helpers.move_cursor { to = { 3, 2 } }
      assert.infoview_contents.are(GOAL)

      reprocess()
      local window = infoview.get_current_infoview().window
      assert.is_true(vim.wait(5000, function()
        return window.o.winhighlight == 'NormalNC:leanInfoProcessing'
      end))
      assert.infoview_contents_nowait.are(GOAL)

      assert.infoview_contents.are(GOAL)
      assert.are.equal('', window.o.winhighlight)
    end)
  )

  it(
    'falls back to show_processing when disabled',
    helpers.clean_buffer(CONTENTS, function()
      vim.g.lean_config = { infoview = { keep_stale_goal = false } }
      helpers.move_cursor { to = { 3, 2 } }
      assert.infoview_contents.are(GOAL)

      reprocess()
      helpers.wait:for_infoview_contents 'Processing file'
      assert.are_not.equal(
        'NormalNC:leanInfoProcessing',
        infoview.get_current_infoview().window.o.winhighlight
      )
    end)
  )
end)
