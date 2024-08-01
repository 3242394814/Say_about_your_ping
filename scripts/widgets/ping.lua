local modname = KnownModIndex:GetModActualName("说说你的ping")
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local TextButton = require "widgets/textbutton"
local function Say(str)
    TheNet:Say(str)
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
	self.cd = nil

	self:StartUpdating()

    self.ping.OnMouseButton = function(_self, button, down, x, y)    --注意:此处应将self.drag_button替换为你要拖拽的widget
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
        if self.vip and GetModConfigData("announce_style",modname) == "VIP" then    --作者专用
            if self.lastPingVal < 0 then
                Say(STRINGS.LMB.. ":flex:无延迟 纵享丝滑~")
            elseif self.lastPingVal <= 2 then
				Say(STRINGS.LMB.. ":beefalo:本地直连 Ping: "..TheNet:GetPing().. "ms ")
            elseif self.lastPingVal <= 30 then
				Say(STRINGS.LMB.. ":heart:极低延迟: " ..TheNet:GetPing().. "ms 。针不戳！")
            elseif self.lastPingVal <= 50 then
				Say(STRINGS.LMB.. ":web:低延迟: " ..TheNet:GetPing().. "ms 。我时刻准备着！")
            elseif self.lastPingVal <= 99 then
				Say(STRINGS.LMB.. ":web:中高延迟: " ..TheNet:GetPing().. "ms 。高Ping战士, 请求摸鱼~")
            elseif self.lastPingVal <= 500 then
				Say(STRINGS.LMB.. ":ghost:高延迟: " ..TheNet:GetPing().. "ms 。这边建议换个服主开服呢:pig:")
            else
				Say(STRINGS.LMB.. ":skull:超高延迟: " ..TheNet:GetPing().. "ms 。这句话发送在10分钟前！")
            end

        elseif GetModConfigData("announce_style",modname) == "VIP" then
                Say(STRINGS.LMB.. "说说你的Ping：请切换为其他宣告样式再进行宣告")

        elseif GetModConfigData("announce_style",modname) == "style" then  --表情+文字
            if self.lastPingVal < 0 then
                Say(STRINGS.LMB.. ":flex:无延迟 纵享丝滑~")
            elseif self.lastPingVal <= 2 then
				Say(STRINGS.LMB.. ":beefalo:本地直连 Ping: "..TheNet:GetPing().. "ms ")
            elseif self.lastPingVal <= 30 then
				Say(STRINGS.LMB.. ":heart:极低延迟: " ..TheNet:GetPing().. "ms 。爱了爱了！")
            elseif self.lastPingVal <= 50 then
				Say(STRINGS.LMB.. ":web:低延迟: " ..TheNet:GetPing().. "ms 。我时刻准备着！")
            elseif self.lastPingVal <= 120 then
				Say(STRINGS.LMB.. ":web:中高延迟: " ..TheNet:GetPing().. "ms 。高Ping战士, 请求摸鱼~")
            elseif self.lastPingVal <= 500 then
				Say(STRINGS.LMB.. ":ghost:高延迟: " ..TheNet:GetPing().. "ms 。网络状态不佳！我无法进行战斗！")
            else
				Say(STRINGS.LMB.. ":skull:超高延迟: " ..TheNet:GetPing().. "ms 。这句话发送在10分钟前！")
            end

        elseif GetModConfigData("announce_style",modname) == "text" then   --仅文字
            if self.lastPingVal < 0 then
                Say(STRINGS.LMB.. "无延迟 纵享丝滑~")
            elseif self.lastPingVal <= 2 then
				Say(STRINGS.LMB.. "本地直连 Ping: "..TheNet:GetPing().. "ms ")
            elseif self.lastPingVal <= 30 then
				Say(STRINGS.LMB.. "极低延迟: " ..TheNet:GetPing().. "ms 。爱了爱了！")
            elseif self.lastPingVal <= 50 then
				Say(STRINGS.LMB.. "低延迟: " ..TheNet:GetPing().. "ms 。我时刻准备着！")
            elseif self.lastPingVal <= 120 then
				Say(STRINGS.LMB.. "中高延迟: " ..TheNet:GetPing().. "ms 。高Ping战士, 请求摸鱼~")
            elseif self.lastPingVal <= 500 then
				Say(STRINGS.LMB.. "高延迟: " ..TheNet:GetPing().. "ms 。网络状态不佳！我无法进行战斗！")
            else
				Say(STRINGS.LMB.. "超高延迟: " ..TheNet:GetPing().. "ms 。这句话发送在10分钟前！")
            end

        elseif GetModConfigData("announce_style",modname) == "false" then  --仅延迟
                Say(STRINGS.LMB.. "Ping: " ..TheNet:GetPing().. "ms")
            end

			self.cd = true
			self.inst:DoSimTaskInTime(self.vip and 0 or 10, function() self.cd = nil end)
		end
	end)
end)

function Ping:OnUpdate(dt)
    local pingVal = TheNet:GetPing()
    --if pingVal < 0 then pingVal = 0 end
    if pingVal ~= self.lastPingVal then
        self.lastPingVal = pingVal

        if self.lastPingVal == -1 then
            self.ping:SetText("服务器主机")
        else
            self.ping:SetText("Ping: "..pingVal)
        end

        if GetModConfigData("color",modname) == false then
            self.ping:SetTextColour(0.9, 0.9, 0.9, 1)
        else
            if self.lastPingVal < 0 then
                self.ping:SetTextColour(0/255, 255/255, 255/255, 255/255)
            elseif self.lastPingVal <= 50 then
                self.ping:SetTextColour(59/255, 242/255, 99/255, 255/255)
            elseif self.lastPingVal <= 120 then
                self.ping:SetTextColour(222/255, 222/255, 99/255, 255/255)
            else
                self.ping:SetTextColour(242/255, 99/255, 99/255, 255/255)
            end
        end
    end

    -- 旧版代码
    -- if EQUIPSLOTS.BACK then
    --     self.backpack = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BACK)
    -- else
    --     self.backpack = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    -- end
    -- if self.backpack and self.backpack.replica.container and Profile:GetIntegratedBackpack() == true then
    --     self.ping:SetPosition(60, -87, 0)--佩戴背包且融合布局 原内容：60,-87,0
    -- else
    --     if GetModConfigData("Position",modname) == 1 then
    --         self.ping:SetPosition(270, -87, 0)--分开布局（默认） 原内容：60,-30,0
    --     else
    --         self.ping:SetPosition(60, -30, 0)
    --     end
    -- end

    --[[
        ↑:使用正数的 Y 坐标值，例如 +1 表示向上移动 1 个单位。
        ↓:使用负数的 Y 坐标值，例如 -1 表示向下移动 1 个单位。
        ←:使用负数的 X 坐标值，例如 -1 表示向左移动 1 个单位。
        →:使用正数的 X 坐标值，例如 +1 表示向右移动 1 个单位。
    ]]

end

return Ping