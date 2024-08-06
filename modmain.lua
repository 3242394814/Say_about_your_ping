-- 自动查询全局变量
GLOBAL.setmetatable(env, {
    __index = function(t, k)
        return GLOBAL.rawget(GLOBAL, k)
    end
})

if not TheNet:IsDedicated() then -- 判断

local ping = require "widgets/ping"
local myname = TheNet:GetLocalUserName()
local function Say(str)
    TheNet:Say(str)
end
TUNING.MODCONFIGDATA = {}
TUNING.MODCONFIGDATA["show_ping_client"] = true -- 其它MOD可通过这个参数判断此MOD是否开启

AddClassPostConstruct("widgets/controls", function(self)
	self.ping = self.bottom_root:AddChild(ping())
	self.ping:SetPosition(625, 30)
--	self.ping.colour = GetModConfigData("color") == false and "white"
end)

local function ModFollowMouse(self)
    --GetWorldPosition获得的坐标是基于屏幕原点的，默认为左下角，当单独设置了原点的时候，这个函数返回的结果和GetPosition的结果一样了，达不到我们需要的效果
    --因为官方没有提供查询原点坐标的接口，所以需要修改设置原点的两个函数，将原点位置记录在widget上
    --注意：虽然默认的屏幕原点为左下角，但是每个widget默认的坐标原点为其父级的屏幕坐标；
    --而当你单独设置了原点坐标后，不仅其屏幕原点改变了，而且坐标原点的位置也改变为屏幕原点了
    local old_sva = self.SetVAnchor
    self.SetVAnchor = function (_self, anchor)
        self.v_anchor = anchor
        return old_sva(_self, anchor)
    end

    local old_sha = self.SetHAnchor
    self.SetHAnchor = function (_self, anchor)
        self.h_anchor = anchor
        return old_sha(_self, anchor)
    end

    --默认的原点坐标为父级的坐标，如果widget上有v_anchor和h_anchor这两个变量，就说明改变了默认的原点坐标
    --我们会在GetMouseLocalPos函数里检查这两个变量，以对这种情况做专门的处理
    --这个函数可以将鼠标坐标从屏幕坐标系下转换到和wiget同一个坐标系下
    local function GetMouseLocalPos(ui, mouse_pos)        --ui: 要拖拽的widget, mouse_pos: 鼠标的屏幕坐标(Vector3对象)
        local g_s = ui:GetScale()                    --ui的全局缩放值
        local l_s = Vector3(0,0,0)
        l_s.x, l_s.y, l_s.z = ui:GetLooseScale()    --ui本身的缩放值
        local scale = Vector3(g_s.x/l_s.x, g_s.y/l_s.y, g_s.z/l_s.z)    --父级的全局缩放值

        local ui_local_pos = ui:GetPosition()        --ui的相对位置（也就是SetPosition的时候传递的坐标）
        ui_local_pos = Vector3(ui_local_pos.x * scale.x, ui_local_pos.y * scale.y, ui_local_pos.z * scale.z)
        local ui_world_pos = ui:GetWorldPosition()
        --如果修改过ui的屏幕原点，就重新计算ui的屏幕坐标（基于左下角为原点的）
        if not (not ui.v_anchor or ui.v_anchor == ANCHOR_BOTTOM) or not (not ui.h_anchor or ui.h_anchor == ANCHOR_LEFT) then
            local screen_w, screen_h = TheSim:GetScreenSize()        --获取屏幕尺寸（宽度，高度）
            if ui.v_anchor and ui.v_anchor ~= ANCHOR_BOTTOM then    --如果修改了原点的垂直坐标
                ui_world_pos.y = ui.v_anchor == ANCHOR_MIDDLE and screen_h/2 + ui_world_pos.y or screen_h - ui_world_pos.y
            end
            if ui.h_anchor and ui.h_anchor ~= ANCHOR_LEFT then        --如果修改了原点的水平坐标
                ui_world_pos.x = ui.h_anchor == ANCHOR_MIDDLE and screen_w/2 + ui_world_pos.x or screen_w - ui_world_pos.x
            end
        end

        local origin_point = ui_world_pos - ui_local_pos    --原点坐标
        mouse_pos = mouse_pos - origin_point

        return Vector3(mouse_pos.x/ scale.x, mouse_pos.y/ scale.y, mouse_pos.z/ scale.z)    --鼠标相对于UI父级坐标的局部坐标
    end

    --修改官方的鼠标跟随，以适应所有情况(垃圾科雷)
    self.FollowMouse = function(_self)
        if _self.followhandler == nil then
            _self.followhandler = TheInput:AddMoveHandler(function(x, y)
                local loc_pos = GetMouseLocalPos(_self, Vector3(x, y, 0))    --主要是将原本的x,y坐标进行了坐标系的转换，使用转换后的坐标来更新widget位置
                _self:UpdatePosition(loc_pos.x, loc_pos.y)
            end)
            _self:SetPosition(GetMouseLocalPos(_self, TheInput:GetScreenPosition()))
        end
    end
end
AddClassPostConstruct("widgets/widget", ModFollowMouse)

if not TheNet:GetIsServer() then -- 判断当前机器是不是服务端，非服务端才能执行这个代码，否则崩溃
    -- 捕获聊天信息，存在关键词就发送自己的Ping
    local oldNetworking_Say = GLOBAL.Networking_Say
    GLOBAL.Networking_Say = function(guid, userid, name, prefab, message, ...)
        if message == "#所有人宣告Ping" or message == "#@".. myname .. "宣告Ping" then
            --Say("我的Ping: " .. TheNet:GetPing() .. "ms")
            if TheNet:GetPing() <= 2 then
                Say("本地直连 Ping: "..TheNet:GetPing().. "ms ")
            elseif TheNet:GetPing() <= 30 then
                Say("极低延迟: " ..TheNet:GetPing().. "ms 。爱了爱了！")
            elseif TheNet:GetPing() <= 50 then
                Say("低延迟: " ..TheNet:GetPing().. "ms 。我时刻准备着！")
            elseif TheNet:GetPing() <= 120 then
                Say("中高延迟: " ..TheNet:GetPing().. "ms 。高Ping战士, 请求摸鱼~")
            elseif TheNet:GetPing() <= 500 then
                Say("高延迟: " ..TheNet:GetPing().. "ms 。网络状态不佳！我无法进行战斗！")
            else
                Say("超高延迟: " ..TheNet:GetPing().. "ms 。这句话发送在10分钟前！")
            end
        end
        return oldNetworking_Say(guid, userid, name, prefab, message, ...)
    end
end

end