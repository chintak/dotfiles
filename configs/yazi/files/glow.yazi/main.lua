-- glow.yazi — markdown previewer for yazi, shelling out to glow.
-- Based on yazi-rs/plugins piper.yazi (MIT), specialized to glow.
--
-- Why the env vars: the child's stdout is a pipe (non-tty), so glow would
-- fall back to the colorless notty style unless (a) CLICOLOR_FORCE=1 forces
-- a color profile and (b) the style is passed explicitly via -s= (an
-- env-set GLOW_STYLE alone does not mark glow's flag as changed). PAGER=cat
-- stops glow's `pager: true` (glow.yml) from spawning less inside the
-- preview. The theme itself lives in configs/glow (onelight.json).

--- @since 26.8.15

local M = {}

local function fail(job, s) ya.preview_widget(job, ui.Text.parse(s):area(job.area):wrap(ui.Wrap.YES)) end

function M:peek(job)
	local child, err = Command("sh")
		:arg({ "-c", 'PAGER=cat CLICOLOR_FORCE=1 glow -w=$w -s="${GLOW_STYLE:-dark}" "$1"', "sh", tostring(job.file.path) })
		:env("w", job.area.w)
		:env("h", job.area.h)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then
		return fail(job, "sh: " .. err)
	end

	local limit = job.area.h
	local i, outs, errs = 0, {}, {}
	repeat
		local next, event = child:read_line()
		if event == 1 then
			errs[#errs + 1] = next
		elseif event ~= 0 then
			break
		end

		i = i + 1
		if i > job.skip then
			outs[#outs + 1] = next
		end
	until i >= job.skip + limit

	child:start_kill()
	if #errs > 0 then
		fail(job, table.concat(errs, ""))
	elseif job.skip > 0 and i < job.skip + limit then
		ya.emit("peek", { math.max(0, i - limit), only_if = job.file.url, upper_bound = true })
	else
		local s = table.concat(outs, ""):gsub("\t", string.rep(" ", rt.preview.tab_size))
		ya.preview_widget(job, ui.Text.parse(s):area(job.area))
	end
end

function M:seek(job) require("code"):seek(job) end

return M
