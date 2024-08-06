name = "说说你的ping"
description =
[[
开启后将在屏幕右下角显示你的Ping值，你可以点击它，点击后你的角色会在聊天中宣告你的Ping是多少。
右键可以拖拽Ping值的显示位置
4.1 版本更新内容：
1.在Ping值小部件上显示客户端网络状态、服务器性能状态
2.重写Ping的宣告内容，并支持自动识别用户是否有对应表情
3.由于重写代码，Ping的文本颜色设置被删除了（应该也没人用白色吧？）

4.0 版本更新内容：
现在你可以直接右键拖拽Ping值小部件了！妈妈再也不用担心位置不够好了

]]
author = "冰冰羊"
version = "4.0"
priority = -2
api_version = 10

dst_compatible = true
client_only_mod = true

icon_atlas = "atlas-0.xml"
icon = "atlas-0.tex"
configuration_options =
{
    {
        name = "remember",
        label = "记住你设置的Ping的显示位置？",
        hover = "如果你设置到了奇怪的地方 可以关闭此选项来复原位置\n这样就可以重新设置位置了，模组依然会保存你最后设置的位置",
        options =
        {
            {description = "是", hover = "" , data = true},
            {description = "否",hover = "", data = false},
        },
        default = true,
    },
    {
        name = "Ping_Style",
        label = "Ping小部件显示内容",
        hover = "",
        options =
        {
            {description = "延迟+客户端/服务器性能",hover = "Ping: 22(网络性能优秀)" , data = true},
            {description = "仅延迟", hover = "Ping: 44" ,data = false},
        },
        default = true,
    },
	{
        name = "Announce_Style",
        label = "宣告样式",
        hover = "请选择你的宣告样式",
        options =
        {
            {description = "表情(如果有)+文字+其它",hover = "󰀗低延迟: 44ms。我时刻准备着！   解锁过的表情才会显示" , data = true},
            {description = "仅延迟", hover = "Ping: 44ms" ,data = false},
        },
        default = true,
    }
}