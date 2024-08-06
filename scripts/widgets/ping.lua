local modname = KnownModIndex:GetModActualName("说说你的ping")
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local TextButton = require "widgets/textbutton"
local my_user_name = TheNet:GetLocalUserName()
local function Say(str)
    TheNet:Say(str)
end

local function SayPing(ping,netscore,performance) -- Ping，客户端网络性能，服务器性能
    local netscore = netscore and netscore+1 -- LUA的Table表下标是从1开始的，所以+1
    local performance = performance and performance+1

    if GetModConfigData("Announce_Style",modname) then  -- 表情+文字
        local function CheckEmoji(emoji) -- 检查玩家是否有这个Emoji表情
            if TheInventory:CheckOwnership('emoji_'..emoji) then
                return ':'..emoji..':'
            else
                return ''
            end
        end

        local pingMessages = {
            {maxPing = 0, message = STRINGS.LMB.. CheckEmoji('flex').. "无延迟 纵享丝滑~"},
            {maxPing = 2, message = STRINGS.LMB.. CheckEmoji('beefalo').. "本地直连 Ping: %dms "},
            {maxPing = 30, message = STRINGS.LMB.. CheckEmoji('heart').. "极低延迟: %dms 。爱了爱了！"},
            {maxPing = 50, message = STRINGS.LMB.. CheckEmoji('web').. "低延迟: %dms 。我时刻准备着！"},
            {maxPing = 120, message = STRINGS.LMB.. CheckEmoji('web').. "中高延迟: %dms 。高Ping战士, 请求摸鱼~"},
            {maxPing = 500, message = STRINGS.LMB.. CheckEmoji('ghost').. "高延迟: %dms 。网络状态不佳！我无法进行战斗！"},
            {maxPing = math.huge, message = STRINGS.LMB.. CheckEmoji('skull').. "超高延迟: %dms 。这句话发送在10分钟前！"}
        }

        local function GetPingMessage(ping)
            for _, pingInfo in ipairs(pingMessages) do
                if ping < pingInfo.maxPing then
                    return string.format(pingInfo.message, ping)
                end
            end
        end

        local netscoreMessage_list = {"客户端网络性能：优秀","客户端网络性能：一般","客户端网络性能较差！"}
        local performanceMessage_list = {"服务器性能：优秀","服务器性能一般","服务器性能较差！"}

        local netscoreMessage = ("   " .. netscoreMessage_list[netscore]) or "" -- 客户端网络性能
        local performanceMessage = (performance and netscore and netscore == 1 and "   但" .. performanceMessage_list[performance]) or (performance and "   " .. performanceMessage_list[performance]) or "" -- 服务器性能

        local message = GetPingMessage(ping)  .. netscoreMessage .. performanceMessage -- 最终消息
        Say(message)

    else -- 仅延迟
        Say(STRINGS.LMB.. "Ping: " ..ping.. "ms")
    end
end

local function LoadAndSetWidgetPosition(widget, identifier)
    local data = {}

    -- 从文件中加载数据
    TheSim:GetPersistentString("Say_about_your_ping.json", function(load_success, str)
        if load_success and string.len(str) > 0 then
            data = json.decode(str) or {}
        else
            print("[说说你的Ping] 加载数据文件失败，恢复Ping小部件至默认位置")
        end

        -- 获取特定控件的位置信息
        local widget_data = data[identifier]
        if widget_data then
            widget:SetPosition(widget_data.x, widget_data.y)
        end
    end)
end

local function SaveData(identifier, data)
    local save_data = LoadAndSetWidgetPosition() or {}
    save_data[identifier] = data
    -- 保存数据到本地文件
    TheSim:SetPersistentString("Say_about_your_ping.json", json.encode(save_data))
end

local function SaveWidgetPosition(widget, identifier)
    if not widget then return end

    local pos = widget:GetPosition()
    -- 将位置保存到文件中
    SaveData(identifier, { x = pos.x, y = pos.y })
end


local Ping = Class(Widget, function(self, owner)
    Widget._ctor(self, "Ping")
	self.root = self:AddChild(Widget("root"))

	self.ping = self.root:AddChild(TextButton())
	-- self.ping:SetPosition(60, -30, 0)
    self.ping:SetFont(NUMBERFONT)
    self.ping:SetTextSize(40)

    self.vip = TheNet:GetUserID() == "KU_pvwb-aTV" --我知道你想干什么
	self.lastPingVal = nil
	self.cd = nil -- 宣告CD
    self.UpdatePingcd = nil -- 更新Ping值小部件的CD
    self.netscore = nil -- 客户端网络性能
    self.performance = nil -- 服务器性能

	self:StartUpdating()

    self.ping.OnMouseButton = function(_self, button, down, x, y)
        if button == MOUSEBUTTON_RIGHT and down then    --鼠标右键按下
            -- _self.draging = true    --标志这个widget正在被拖拽
            _self:FollowMouse()     --开启控件的鼠标跟随
        elseif button == MOUSEBUTTON_RIGHT then            --鼠标右键抬起
            _self:StopFollowMouse()        --停止控件的跟随
            SaveWidgetPosition(_self, "Position")
        end
    end

    -- 初始化小部件位置
    if GetModConfigData("remember",modname) then
        LoadAndSetWidgetPosition(self.ping, "Position")
    end

    self.ping:SetOnClick(function()
        if not self.cd then
            SayPing(self.lastPingVal,self.netscore,self.performance) -- 宣告网络情况
			self.cd = true
			self.inst:DoSimTaskInTime(self.vip and 0 or 10, function() self.cd = nil end)
		end
	end)
end)

function Ping:OnUpdate(dt)
    local pingVal = TheNet:GetPing()
    --if pingVal < 0 then pingVal = 0 end
    -- if pingVal ~= self.lastPingVal then
    if not self.UpdatePingcd then
        self.lastPingVal = pingVal
        self.UpdatePingcd = true
        self.inst:DoSimTaskInTime(1, function() self.UpdatePingcd = nil end)

        if pingVal == -1 then
            self.ping:SetText("服务器主机")
            self.ping:SetTextColour(0/255, 255/255, 255/255, 255/255)
        else
            -- 检测服务器性能并修改Ping的显示方式
            local ClientObjs = TheNet:GetClientTable()
            if ClientObjs then
                for _, k in pairs(ClientObjs) do
                    if k.performance ~= nil then
                        if k.performance == 2 or k.performance == 1 then
                            self.performance = k.performance -- 设置服务器性能
                        else
                            self.performance = nil
                        end
                    end

                    if k.netscore ~= nil and k.name == my_user_name then
                        self.netscore = k.netscore -- 设置客户端网络性能
                    end
                end
            end
            if GetModConfigData("Ping_Style",modname) then
                if (self.netscore) == 2 then -- 客户端网络性能较差
                    self.ping:SetTextColour(242/255, 99/255, 99/255, 255/255) -- 红色
                    self.ping:SetText("Ping: "..pingVal.."\n(网络性能较差)")
                elseif (self.performance) == 2 then -- 服务器性能较差
                    self.ping:SetTextColour(242/255, 99/255, 99/255, 255/255) -- 红色
                    self.ping:SetText("Ping: "..pingVal.."\n(服务器性能较差)")
                elseif (self.performance) == 1 then -- 服务器性能一般
                    self.ping:SetTextColour(222/255, 222/255, 99/255, 255/255) -- 黄色
                    self.ping:SetText("Ping: "..pingVal.."\n(服务器性能一般)")
                elseif (self.netscore) == 1 then -- 客户端网络性能一般
                    self.ping:SetTextColour(222/255, 222/255, 99/255, 255/255) -- 黄色
                    self.ping:SetText("Ping: "..pingVal.."\n(网络性能一般)")
                elseif (self.netscore) == 0 and pingVal > 50 then -- 客户端网络性能优秀,延迟>50
                    self.ping:SetTextColour(222/255, 222/255, 99/255, 255/255) -- 黄色
                    self.ping:SetText("Ping: "..pingVal.."\n(网络性能优秀)")
                elseif (self.netscore) == 0 and pingVal <= 50 then -- 客户端网络性能优秀,延迟<50
                    self.ping:SetTextColour(59/255, 242/255, 99/255, 255/255) -- 绿色
                    self.ping:SetText("Ping: "..pingVal.."\n(网络性能优秀)")
                else
                    self.ping:SetText("Ping: "..pingVal) -- 默认显示状态（根据Ping来决定颜色）
                    if pingVal <= 50 then
                        self.ping:SetTextColour(59/255, 242/255, 99/255, 255/255) -- 绿色
                    elseif pingVal <= 120 then
                        self.ping:SetTextColour(222/255, 222/255, 99/255, 255/255) -- 黄色
                    else
                        self.ping:SetTextColour(242/255, 99/255, 99/255, 255/255) -- 红色
                    end
                end
            else
                self.ping:SetText("Ping: "..pingVal) -- 默认显示状态（根据Ping来决定颜色）
                if pingVal <= 50 then
                    self.ping:SetTextColour(59/255, 242/255, 99/255, 255/255) -- 绿色
                elseif pingVal <= 120 then
                    self.ping:SetTextColour(222/255, 222/255, 99/255, 255/255) -- 黄色
                else
                    self.ping:SetTextColour(242/255, 99/255, 99/255, 255/255) -- 红色
                end
            end
        end
    end
end

return Ping