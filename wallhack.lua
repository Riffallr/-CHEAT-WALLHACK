script_name("Wallhack")
script_author("Riffall")
script_description("/wallhack or HOME for settings")
script_version("1")


require "lib.moonloader"
local vkeys = require "vkeys"
local ffi = require "ffi"
local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
-- local bonesId = {1, 2, 3, 4, 5, 6, 22, 23, 24, 32, 33, 34, 41, 42, 43, 44, 51, 52, 53, 54}
local m = require "memory"
local imgui = require "ImGui"
local inicfg = require "inicfg"

local cfg = inicfg.load({
    settings = {
        enable = false,
        nicknames = false,
        bones = false,
        clistColorBones = false,
        lineToPeds = false,
        hitBox = false,
        lineToPedsClist = false,
        nicknamesClist = false,
        hitBoxClist = false,
        loadedMessage = true,
    },
})
inicfg.save(cfg)


local font = renderCreateFont("Tahoma", 10, 1)
local scriptColor = 0xafeeee
local imguiFontSize = nil


local window = imgui.ImBool(false)
local bones = imgui.ImBool(cfg.settings.bones)
local nicknames = imgui.ImBool(cfg.settings.nicknames)
local enable = imgui.ImBool(cfg.settings.enable)
local clistColorBones = imgui.ImBool(cfg.settings.clistColorBones)
local lineToPeds = imgui.ImBool(cfg.settings.lineToPeds)
local hitBox = imgui.ImBool(cfg.settings.hitBox)
local lineToPedsClist = imgui.ImBool(cfg.settings.lineToPedsClist)
local nicknamesClist = imgui.ImBool(cfg.settings.nicknamesClist)
local hitBoxClist = imgui.ImBool(cfg.settings.hitBoxClist)
local loadedMessage = imgui.ImBool(cfg.settings.loadedMessage)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end


    bones.v = cfg.settings.bones
    nicknames.v = cfg.settings.nicknames
    enable.v = cfg.settings.enable
    clistColorBones.v = cfg.settings.clistColorBones
    lineToPeds.v = cfg.settings.lineToPeds
    hitBox.v = cfg.settings.hitBox
    lineToPedsClist.v = cfg.settings.lineToPedsClist
    nicknamesClist.v = cfg.settings.nicknamesClist
    hitBoxClist.v = cfg.settings.hitBoxClist
    loadedMessage.v = cfg.settings.loadedMessage


    if loadedMessage.v then
        sampAddChatMessage(string.format("%s {135e58}loaded.", thisScript().name), scriptColor)
    end

    sampRegisterChatCommand("wallhack", cmd_wallhack)

    while true do
        wait(0)
        if wasKeyPressed(vkeys.VK_HOME) then
            window.v = not window.v
        end
        imgui.Process = window.v
        wallhack()

    end
end


local function ApplyTheme()
    local style = imgui.GetStyle()
    local colors = style.Colors
    
    style.WindowPadding = imgui.ImVec2(10, 20)
    style.WindowRounding = 5
    style.FramePadding = imgui.ImVec2(10, 5)
    style.FrameRounding = 2
    style.ItemSpacing = imgui.ImVec2(10, 5)
    style.ItemInnerSpacing = imgui.ImVec2(5, 10)
    style.IndentSpacing = 10
    style.GrabMinSize = 5
    style.WindowTitleAlign = imgui.ImVec2(0.50, 0.50)
    style.ButtonTextAlign = imgui.ImVec2(0.50, 0.50)

    colors[imgui.Col.WindowBg] = imgui.ImVec4(1.00, 1.00, 1.00, 0.04)
    colors[imgui.Col.TitleBg] = imgui.ImVec4(0.29, 0.29, 0.42, 1.00)
    colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0, 0, 20, 215)
    colors[imgui.Col.SliderGrab] = imgui.ImVec4(255, 0, 0, 255)
    
end

function imgui.BeforeDrawFrame()
    if imguiFontSize == nil then
        imguiFontSize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 12.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end

    cfg.settings.bones = bones.v
    cfg.settings.nicknames = nicknames.v
    cfg.settings.enable = enable.v
    cfg.settings.clistColorBones = clistColorBones.v
    cfg.settings.lineToPeds = lineToPeds.v
    cfg.settings.hitBox = hitBox.v
    cfg.settings.lineToPedsClist = lineToPedsClist.v
    cfg.settings.nicknamesClist = nicknamesClist.v
    cfg.settings.hitBoxClist = hitBoxClist.v
    cfg.settings.loadedMessage = loadedMessage.v

    inicfg.save(cfg)
end

function imgui.OnDrawFrame()
    ApplyTheme()
    local resX, resY = getScreenResolution()
    if window.v then
        imgui.SetNextWindowSize(imgui.ImVec2(500,250), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin("Wallhack settings", window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar)
        imgui.Checkbox("Nicknames", nicknames)
        imgui.SameLine(350)
        imgui.Checkbox("Clist Nickname", nicknamesClist)
        imgui.Checkbox("Bones", bones)
        imgui.SameLine(350)
        imgui.Checkbox("Clist Color Bones", clistColorBones)
        imgui.Checkbox("Line To Peds", lineToPeds)
        imgui.SameLine(350)
        imgui.Checkbox("Clist line", lineToPedsClist)
        imgui.Checkbox("HitBox", hitBox)
        imgui.SameLine(350)
        imgui.Checkbox("HitBox Clist", hitBoxClist)
        imgui.NewLine()
        imgui.Checkbox("Enable", enable)
        imgui.Separator()
        imgui.PushFont(imguiFontSize)
        imgui.Text("Author: Riffall")
        imgui.SameLine(350)
        imgui.Checkbox("Loaded Message", loadedMessage)
        imgui.PopFont()
        imgui.End()
    end
end


function getBonesCoordinates(id, handle)
    local pedptr = getCharPointer(handle)
    local vec = ffi.new("float[3]")
    getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
    return vec[0], vec[1], vec[2]
end

function join_rgba(r,g, b, a)
    local rgba = b
    rgba = bit.bor(rgba, bit.lshift(g, 8))
    rgba = bit.bor(rgba, bit.lshift(r, 16))
    rgba = bit.bor(rgba, bit.lshift(a, 24))
    return rgba
end

function explode_rgba(rgba)
    local r = bit.band(bit.rshift(rgba, 16), 0xFF)
    local g = bit.band(bit.rshift(rgba, 8), 0xFF)
    local b = bit.band(rgba, 0xFF)
    local a = bit.band(bit.rshift(rgba, 24), 0xFF)
  return r, g, b, a
end

function cmd_wallhack()
    window.v = not window.v
    imgui.Process = window.v
end


function drawHitBox(ped, clist)
    local posX, posY, posZ = getCharCoordinates(ped)
    -- 0.3 0.5 1 0.9
    local width = 0.3
    local length = 0.3
    local height = 1

    local top = posZ + height
    local bottom = posZ - 0.9

    local corners = {
        -- head
        {posX - width, posY - length, top},
        {posX + width, posY - length, top},
        {posX + width, posY + length, top},
        {posX - width, posY + length, top},
        -- bottom
        {posX - width, posY - length, bottom},
        {posX + width, posY - length, bottom},
        {posX + width, posY + length, bottom},
        {posX - width, posY + length, bottom},
    }
    local screenCorners = {}
    local enableHitBox = true
    for t = 1,8 do
        local hbX, hbY = convert3DCoordsToScreen(corners[t][1], corners[t][2], corners[t][3])
        if hbX and hbY then
            screenCorners[t] = {hbX, hbY}
        else
            enableHitBox = false
        end
    end

    if not enableHitBox then
        return
    end
    renderDrawLine(screenCorners[1][1], screenCorners[1][2], screenCorners[2][1], screenCorners[2][2], 1, clist)
    renderDrawLine(screenCorners[2][1], screenCorners[2][2], screenCorners[3][1], screenCorners[3][2], 1, clist)
    renderDrawLine(screenCorners[3][1], screenCorners[3][2], screenCorners[4][1], screenCorners[4][2], 1, clist)
    renderDrawLine(screenCorners[4][1], screenCorners[4][2], screenCorners[1][1], screenCorners[1][2], 1, clist)
    renderDrawLine(screenCorners[5][1], screenCorners[5][2], screenCorners[6][1], screenCorners[6][2], 1, clist)
    renderDrawLine(screenCorners[6][1], screenCorners[6][2], screenCorners[7][1], screenCorners[7][2], 1, clist)
    renderDrawLine(screenCorners[7][1], screenCorners[7][2], screenCorners[8][1], screenCorners[8][2], 1, clist)
    renderDrawLine(screenCorners[8][1], screenCorners[8][2], screenCorners[5][1], screenCorners[5][2], 1, clist)
    renderDrawLine(screenCorners[1][1], screenCorners[1][2], screenCorners[5][1], screenCorners[5][2], 1, clist)
    renderDrawLine(screenCorners[2][1], screenCorners[2][2], screenCorners[6][1], screenCorners[6][2], 1, clist)
    renderDrawLine(screenCorners[3][1], screenCorners[3][2], screenCorners[7][1], screenCorners[7][2], 1, clist)
    renderDrawLine(screenCorners[4][1], screenCorners[4][2], screenCorners[8][1], screenCorners[8][2], 1, clist)
end



function wallhack()
    if enable.v then
        for i = 0, sampGetMaxPlayerId() do
            if sampIsPlayerConnected(i) then
                local result, cped = sampGetCharHandleBySampPlayerId(i)
                if result and doesCharExist(cped) and isCharOnScreen(cped) then


                    local clist
                    if clistColorBones.v then
                        clist = sampGetPlayerColor(i)
                        local rr, gg, bb, aa = explode_rgba(clist)
                        clist = join_rgba(rr, gg, bb, 255)
                    else
                        clist = -1
                    end

                    if lineToPeds.v then
                        if lineToPedsClist.v then
                            clist = sampGetPlayerColor(i)
                            local rr, gg, bb, aa = explode_rgba(clist)
                            clist = join_rgba(rr, gg, bb, 255)
                        else
                            clist = -1
                        end


                        local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
                        local myPosX, myPosY = convert3DCoordsToScreen(myX, myY, myZ)
                        local lineBone = 3
                        local targetX, targetY, targetZ = getBonesCoordinates(lineBone, cped)
                        local targetPosX, targetPosY = convert3DCoordsToScreen(targetX, targetY, targetZ)
                        
                        renderDrawLine(myPosX, myPosY, targetPosX, targetPosY, 0.5, clist)
                    end

                    if nicknames.v then
                        if nicknamesClist.v then
                            clist = sampGetPlayerColor(i)
                            local rr, gg, bb, aa = explode_rgba(clist)
                            clist = join_rgba(rr, gg, bb, 255)
                        else
                            clist = -1
                        end


                        local playerNickname = sampGetPlayerNickname(i)
                        local pedNameX, pedNameY, pedNameZ = getBonesCoordinates(3, cped)
                        local screenX, screenY = convert3DCoordsToScreen(pedNameX, pedNameY, pedNameZ)

                        renderFontDrawText(font, playerNickname, screenX - 50, screenY - 50, clist)
                    end

                    if hitBox.v then
                        if hitBoxClist.v then
                            clist = sampGetPlayerColor(i)
                            local rr, gg, bb, aa = explode_rgba(clist)
                            clist = join_rgba(rr, gg, bb, 255)
                        else
                            clist = -1
                        end
                        drawHitBox(cped, clist)
                    end

                    if bones.v then
                        local bonesId = {1, 2, 3, 4, 5, 6, 22, 21, 23, 24, 31, 32, 33, 34, 41, 42, 43, 51, 52, 53}
                        for all = 1, #bonesId do
                            posX_1, posY_1, posZ_1 = getBonesCoordinates(bonesId[all], cped)
                            posX_2, posY_2, posZ_2 = getBonesCoordinates(bonesId[all] + 1, cped)
                            pos1, pos2 = convert3DCoordsToScreen(posX_1, posY_1, posZ_1)
                            pos3, pos4 = convert3DCoordsToScreen(posX_2, posY_2, posZ_2)

                            renderDrawLine(pos1, pos2, pos3, pos4, 1, clist)
                        end

                        for all = 4, 5 do
                        local posX_2, posY_2, posZ_2 = getBonesCoordinates(all * 10 + 1, cped)
                        local pos3, pos4 = convert3DCoordsToScreen(posX_2, posY_2, posZ_2)
                        renderDrawLine(pos1, pos2, pos3, pos4, 1, clist)
                        end
                    end
                end
            end
        end
    end
end