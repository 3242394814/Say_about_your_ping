name = "说说你的ping"
description =
[[
开启后将在屏幕右下角显示你的Ping值，你可以点击它，点击后你的角色会在聊天中宣告你的Ping是多少。
右键可以拖拽Ping值的显示位置

4.0 版本更新内容：
现在你可以直接右键拖拽Ping值小部件了！妈妈再也不用担心位置不够好了

修改默认通讯频率的方法：
1、在存档的cluster.ini的[NETWORK]下增加一行 tick_rate = 60
2、在steam饥荒联机版通用属性中的启动选项填写 -tick_rate 60
(填写的数字只能是15~60以内的数字)
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
        name = "color",
        label = "文本颜色",
        hover = "更改文本颜色",
        options =
        {
            {description = "自适应", data = true},
            {description = "仅白色", data = false},
        },
        default = true,
    },
	{
        name = "announce_style",
        label = "宣告样式",
        hover = "请选择你的宣告样式",
        options =
        {
            {description = "表情+文字",hover = "󰀗低延迟: 44ms。我时刻准备着！   解锁过的表情才能正常显示" , data = "style"},
            {description = "仅文字", hover = "低延迟: 44ms。我时刻准备着！" ,data = "text"},
            {description = "仅延迟", hover = "Ping:44ms" ,data = "false"},
            {description = "作者专用", hover = "作者自己用的，普通用户请不要选择这个选项" ,data = "VIP"},
        },
        default = "style",
    }
}