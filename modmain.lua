-- 自动查询全局变量
GLOBAL.setmetatable(env, {
    __index = function(t, k)
        return GLOBAL.rawget(GLOBAL, k)
    end
})

-- 语言检测

local lang = GetModConfigData("lang") or "auto"
if lang == "auto" then
    lang = GLOBAL.LanguageTranslator.defaultlang
end

local chinese_languages =
{
    zh = "zh", -- Chinese for Steam
    zhr = "zh", -- Chinese for WeGame
    ch = "zh", -- Chinese mod
    chs = "zh", -- Chinese mod
    sc = "zh", -- simple Chinese
    zht = "zh", -- traditional Chinese for Steam
	tc = "zh", -- traditional Chinese
	cht = "zh", -- Chinese mod
}

if chinese_languages[lang] ~= nil then
    lang = chinese_languages[lang]
else
    lang = "en"
end

modimport("languages/"..lang..".lua") -- 加载翻译文件

-- 以下代码的功能：
-- 一个客户端按键盘上的某个键会发请求到服务器
-- 服务器收到客户端请求后，发请求到所有客户端
-- 所有客户端把自己的Ping发到服务器
-- 服务器把Ping再发给所有的客户端
-- 客户端打印收集到的Ping

local function canactive()
    if not TheFrontEnd then return true end --防止崩溃
    if InGamePlay() and not TheFrontEnd:GetActiveScreen():IsEditing() then
        return true
    end
    return false
end


if GetModConfigData("showping_key") then
    mykey = _G[GetModConfigData("showping_key")]
    TheInput:AddKeyDownHandler(mykey, function()   --第一步，监听键盘事件，客户端按下按键后发送请求1
        if not canactive() or TheInput:IsKeyDown(GLOBAL.KEY_CTRL) then return end --编辑内容和按住Ctrl时不起效
        if TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) then --当Shift和自定义键同时按下时才有用
            SendModRPCToServer(MOD_RPC["show_ping"]["request_ping"], TheNet:GetLocalUserName()..STRINGS.REQUEST_PING)
        end
    end)
end

--添加RPC1，当客户端发送请求1时，服务器会发送请求2来申请所有玩家的Ping
AddModRPCHandler("show_ping","request_ping", function(player, str)
    --print(str)
    SendModRPCToClient(CLIENT_MOD_RPC["show_ping"]["request_ping"],id_table, str)--第二步，服务器收到请求1后，发送请求2（str）到所有客户端。
end)

--添加RPC2
AddModRPCHandler("show_ping","myping", function(player, Getping)
    --print(Getping)
    SendModRPCToClient(CLIENT_MOD_RPC["show_ping"]["s2c_ping"],id_table, Getping)--第四步，服务器收到Ping后发给客户端
end)

--在服务端注册,这里仅作为注册用，不需要实现功能
if TheNet:GetIsServer() then
    AddClientModRPCHandler("show_ping", "request_ping",function(str) end)--请求Ping
    AddClientModRPCHandler("show_ping", "s2c_ping",function(str) end)--发送Ping
end

if TheNet:GetIsClient() then
--客户端收到服务器的请求2后会发送自己的Ping到服务器
AddClientModRPCHandler("show_ping", "request_ping",function(str)
    Networking_Say(-1, -1, STRINGS.PING_MODNAME, nil, str, {0.196, 0.804, 0.196, 1}, false, 'none')
    SendModRPCToServer(MOD_RPC["show_ping"]["myping"], TheNet:GetLocalUserName()..STRINGS.THE_PING_IS..TheNet:GetPing().."ms")--第三步，收到请求后发送自己的Ping到服务器
end)


--第五步，客户端处理服务器发过来的Ping
AddClientModRPCHandler("show_ping", "s2c_ping",function(pingData)
    --print(pingData)
    Networking_Say(-1, -1, STRINGS.PING_MODNAME, nil, pingData, {1, 1, 1, 1}, false, 'none')
end)
end

if not TUNING.SAYABOUTYOURPING_MODCONFIGDATA then TUNING.SAYABOUTYOURPING_MODCONFIGDATA = {} end
if TUNING.SAYABOUTYOURPING_MODCONFIGDATA["show_ping_client"] then print("说说你的Ping-服务器版: 检测到客户端版说说你的Ping已开启,停止加载服务器版的部分功能") end

if not TheNet:IsDedicated() and not TUNING.SAYABOUTYOURPING_MODCONFIGDATA["show_ping_client"] then -- 非专用服务器且未开启客户端版说说你的Ping才通过
    local ping = require "widgets/ping"
    local myname = TheNet:GetLocalUserName()
    local function Say(str)
        TheNet:Say(str)
    end

    AddClassPostConstruct("widgets/controls", function(self)
        self.ping = self.bottom_root:AddChild(ping())
        self.ping:SetPosition(625, 35)
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

    -- 捕获聊天信息，存在关键词就发送自己的Ping
    if not TheNet:GetIsServer() then -- 判断当前机器是不是服务端，非服务端才能执行这个代码，否则崩溃
        local oldNetworking_Say = GLOBAL.Networking_Say
        GLOBAL.Networking_Say = function(guid, userid, name, prefab, message, ...)
            if message == "#所有人宣告Ping" or message == "#@".. myname .. " Ping" or message == "#AnnouncePingToAll" then
                --Say("我的Ping: " .. TheNet:GetPing() .. "ms")
                if TheNet:GetPing() <= 2 then
                    Say(string.format(STRINGS.PING_LOCAL, TheNet:GetPing()))
                elseif TheNet:GetPing() <= 30 then
                    Say(string.format(STRINGS.PING_LOW, TheNet:GetPing()))
                elseif TheNet:GetPing() <= 50 then
                    Say(string.format(STRINGS.PING_MEDIUM, TheNet:GetPing()))
                elseif TheNet:GetPing() <= 120 then
                    Say(string.format(STRINGS.PING_HIGH, TheNet:GetPing()))
                elseif TheNet:GetPing() <= 500 then
                    Say(string.format(STRINGS.PING_VERY_HIGH, TheNet:GetPing()))
                else
                    Say(string.format(STRINGS.PING_EXTREME, TheNet:GetPing()))
                end
            end
            return oldNetworking_Say(guid, userid, name, prefab, message, ...)
        end
    end
end