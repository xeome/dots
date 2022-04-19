local sense=-30
local speed = mp.get_property("speed")
local detect = false
function f(msg)
	if string.find(msg.text, "silence_end") and detect then
		mp.set_property("speed",speed)
		endmsg=msg.text
		detect = false
		--print("end")
	elseif string.find(msg.text, "silence_start") and detect==false then
		speed = mp.get_property("speed")
		mp.set_property("speed",2.5)
		startmsg=msg.text
		detect = true
		--print("start")
	end
end

function sensitivity(change)
	sense = sense + change
	mp.osd_message("detection sensitivity: "..sense.."dB")
	if string.find(mp.get_property("af"), "silencedetect") then
		mp.set_property("af", "lavfi=[silencedetect=n="..sense.."dB:d=1]")
	end
end

function toggle()
	mp.command("af toggle lavfi=[silencedetect=n="..sense.."dB:d=1]")
	if string.find(mp.get_property("af"), "silencedetect") then
		mp.osd_message("Silence detection enabled")
		mp.register_event("log-message", f)
	else
		mp.set_property("speed",speed)
		mp.osd_message("Silence detection disabled")
		mp.unregister_event(f)
	end
end

function det(msg)
	if string.find(msg.text, "max_volume") then
		mp.osd_message(msg.text)
	end
end
local timer
function voldetect()
	if timer~=nil and timer:is_enabled() then
		timer:kill()
		mp.unregister_event(det)
	else
		mp.register_event("log-message", det)
		timer = mp.add_periodic_timer(0.1, function()
			mp.command("no-osd af toggle lavfi=[volumedetect]")
			mp.add_timeout(0.09, function()
				mp.command("no-osd af toggle lavfi=[volumedetect]")
			end)
		end)
	end
end

mp.enable_messages("v")
mp.add_key_binding("F2", "toggle", toggle)
mp.add_key_binding("alt+F2", "voldetect", voldetect)
mp.add_key_binding("shift+F2", "sense-up", function() sensitivity(1) end, "repeatable")
mp.add_key_binding("ctrl+F2", "sense-down", function() sensitivity(-1) end, "repeatable")
