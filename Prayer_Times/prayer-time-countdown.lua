Prayers = {
	"Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha", "Midnight"
}


function TimeToMinutes(timeStr)
	local hours, minutes = timeStr:match("(%d+):(%d+)")
	return tonumber(hours) * 60 + tonumber(minutes)
end

function GetCurrentTime()
    local os_time = os.time()
    local current_time = os.date("%H:%M", os_time)
    return current_time
end

function GetMeasuresTimes()	

	local prayerTimes = {}
    for _, prayer in ipairs(Prayers) do
        local measureName = "Measure" .. prayer
        local measure = SKIN:GetMeasure(measureName)
        if measure then
            local prayerTime = measure:GetStringValue()
			if prayerTime and prayerTime ~= "" then
				prayerTimes[prayer] = TimeToMinutes(prayerTime)
			end
            
        else
            print("Could not find measure for " .. measureName)
        end
    end
	
	return prayerTimes
end

function GetCurrentPrayerAndTimeRemaining(Prayer_times_table, current_time)
	
	for index, prayer in ipairs(Prayers) do
		local prayer_time = Prayer_times_table[prayer]
        if prayer_time >= current_time and prayer ~= 'Midnight' and prayer ~= 'Sunrise' then			
            local remainingMinutes = prayer_time - current_time
            local hours = math.floor(remainingMinutes / 60)
            local minutes = remainingMinutes % 60
			return prayer, string.format("%02d", hours), string.format("%02d", minutes), remainingMinutes

        end
    end

    -- If no prayer time is found (past last prayer), return to Fajr		
	local remainingMinutes = (24 * 60) + Prayer_times_table['Fajr'] - current_time
	local hours = math.floor(remainingMinutes / 60)
	local minutes = remainingMinutes % 60	
	return 'Fajr', string.format("%02d", hours), string.format("%02d", minutes), remainingMinutes

	
end

function GetPreviousPrayerAndTimeElapsed(Prayer_times_table, current_time)
	
	for i = #Prayers, 1, -1 do
		local prayer = Prayers[i]
		local prayer_time = Prayer_times_table[prayer]
        if prayer_time < current_time and prayer ~= 'Midnight' and prayer ~= 'Sunrise' then	
            local elapsedMinutes = current_time - prayer_time
            local hours = math.floor(elapsedMinutes / 60)
            local minutes = elapsedMinutes % 60
			return prayer, string.format("%02d", hours), string.format("%02d", minutes), elapsedMinutes

        end
    end

    -- If no prayer time is found (past last prayer), return to Isha		
	local elapsedMinutes = current_time + (24 * 60) - Prayer_times_table['Isha'] 
	local hours = math.floor(elapsedMinutes / 60)
	local minutes = elapsedMinutes % 60	
	return 'Isha', string.format("%02d", hours), string.format("%02d", minutes), elapsedMinutes

	
end

function Update()	
	Color_r = SKIN:GetVariable('Color_r')
	Color = SKIN:GetVariable('Color')
	AthanPlayed = SKIN:GetVariable('AthanPlayed')
	Prayer_times_table = GetMeasuresTimes()
	local current_time = TimeToMinutes(GetCurrentTime())

	-- for key, value in pairs(Prayer_times_table) do
	-- 	print(key, value)
	-- end

	local prayer, hours, minutes, remainingMinutes = GetCurrentPrayerAndTimeRemaining(Prayer_times_table, current_time)

	local prayer_e, hours_e, minutes_e, elapsedMinutes = GetPreviousPrayerAndTimeElapsed(Prayer_times_table, current_time)  
    
	SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownName', 'Text', 'till '.. prayer)
	SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownHr', 'Text', hours)
	SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin', 'Text', minutes)
    
	SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownName_E', 'Text', 'Since '.. prayer_e)
	SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownHr_E', 'Text', hours_e)
	SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_E', 'Text', minutes_e)
	
	SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownName_E_hover', 'Text', 'Since '.. prayer_e)
	SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownHr_E_hover', 'Text', hours_e)
	SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_E_hover', 'Text', minutes_e)
	if remainingMinutes <= 15 then
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin', 'FontColor', Color_r)
	else
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin', 'FontColor', Color)		
	end

	if elapsedMinutes >= 5  and  elapsedMinutes <= 20 then
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_E', 'FontColor', Color_r)
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_E_hover', 'FontColor', Color_r)
	else
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_E', 'FontColor', Color)		
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_E_hover', 'FontColor', Color)		
	end

	if elapsedMinutes >60 then
		SKIN:Bang('!HideMeter', 'MeterNextPrayerCountdownName_E')
		SKIN:Bang('!HideMeter', 'MeterNextPrayerCountdownHrMin_E')
		SKIN:Bang('!HideMeter', 'MeterNextPrayerCountdownHr_E')
		SKIN:Bang('!HideMeter', 'MeterNextPrayerCountdownMin_E')
	else
		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownName_E')
		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownHrMin_E')
		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownHr_E')
		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownMin_E')
	end


	if remainingMinutes==0 and AthanPlayed=='False' then
		SKIN:Bang('Play athan.wav')
		SKIN:Bang('!SetVariable', 'AthanPlayed', 'True')
	elseif remainingMinutes~=0 and AthanPlayed=='True'then
		SKIN:Bang('!SetVariable', 'AthanPlayed', 'False')
	end

	-- Once we reach maghrib then we should enter the next day. 
	-- Once it's midnight the logic will still hold since current_time will be less
	-- than all of the prayers inlcuing maghrib and the skin will automatically 
	-- call for the next day
	if Prayer_times_table['Maghrib'] < current_time then
		SKIN:Bang('!SetVariable', 'Tomorrow',  86400)
	else
		SKIN:Bang('!SetVariable', 'Tomorrow',  0)
	end

	if Prayer_times_table['Isha'] < current_time and Prayer_times_table['Midnight'] > current_time then
		local remainingMinutes_Midnight = Prayer_times_table['Midnight'] - current_time
		local hours_Midnight = math.floor(remainingMinutes_Midnight / 60)
		local minutes_Midnight = remainingMinutes_Midnight % 60

		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownHrMin_S')
		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownHr_S')
		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownName_S')
		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownMin_S')
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownName_S', 'Text', 'till Midnight')
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownHr_S', 'Text', string.format("%02d", hours_Midnight))
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_S', 'Text', string.format("%02d", minutes_Midnight))
		if remainingMinutes_Midnight <= 15 then

			SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_S', 'FontColor', Color_r)
		else

			SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_S', 'FontColor', Color)
			
		end
	
	elseif Prayer_times_table['Fajr'] < current_time and Prayer_times_table['Sunrise'] > current_time then

		local remainingMinutes_Sunrise = Prayer_times_table['Sunrise'] - current_time
		local hours_Sunrise = math.floor(remainingMinutes_Sunrise / 60)
		local minutes_Sunrise = remainingMinutes_Sunrise % 60
		
		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownHrMin_S')
		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownHr_S')
		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownName_S')
		SKIN:Bang('!ShowMeter', 'MeterNextPrayerCountdownMin_S')
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownName_S', 'Text', 'till Sunrise')
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownHr_S', 'Text', string.format("%02d", hours_Sunrise))
		SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_S', 'Text', string.format("%02d", minutes_Sunrise))
		if remainingMinutes_Sunrise <= 15 then
			
			SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_S', 'FontColor', Color_r)
		else

			SKIN:Bang('!SetOption', 'MeterNextPrayerCountdownMin_S', 'FontColor', Color)
			
		end
	
	else
		SKIN:Bang('!HideMeter', 'MeterNextPrayerCountdownHrMin_S')
		SKIN:Bang('!HideMeter', 'MeterNextPrayerCountdownHr_S')
		SKIN:Bang('!HideMeter', 'MeterNextPrayerCountdownName_S')
		SKIN:Bang('!HideMeter', 'MeterNextPrayerCountdownMin_S')
	

	end

	
end
