#Requires AutoHotkey v2.0

; https://stackoverflow.com/questions/43298908/how-to-add-administrator-privileges-to-autohotkey-script
#SingleInstance Force
;@Ahk2Exe-UpdateManifest 1
full_command_line := DllCall("GetCommandLine", "str")
if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
  try
  {
    if A_IsCompiled
      Run '*RunAs "' A_ScriptFullPath '" /restart'
    else
      Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
  }
  ExitApp
}

SendMode "Event"
GroupAdd "HoYoGame", "ahk_exe GenshinImpact.exe"
GroupAdd "HoYoGame", "ahk_exe ZenlessZoneZero.exe"

/*
    ==========================================================
    檢測
    ==========================================================
*/
;立刻檢測是否前台
CheckActive
;每5秒檢測是否前台
SetTimer CheckActive, 5000

CheckActive(){
    if WinWaitActive('ahk_group HoYoGame',,5){
        Suspend false
        Settimer MoveCursor, 16
    }else{
        Suspend true
    }
}

/*
==========================================================
主要
==========================================================
*/
#HotIf WinActive("ahk_group HoYoGame")
    ; 按Alt+N暫停所有熱鍵, 再次Alt+N啟動
    #SuspendExempt
    ~!n::
    {
        Suspend
        ToolTip a_isSuspended ? "插件已暫停":"插件運作中"
        SetTimer CheckActive, (A_IsSuspended) == 1 ? 0 : 5000
        Settimer MoveCursor, (A_IsSuspended) == 1 ? 0 : 16
        Sleep 3000
        ToolTip
    }

    ; 按Alt+R重載腳本
    !r::Reload

    ; 按Ctrl+Alt+E退出腳本
    ^!e::{
        MsgBox "ZZZHKeys 已停止(Terminated)",'ZZZHKeys.exe' , 'OK'
        ExitApp
    }
    #SuspendExempt false
    

    ;以下是映射設定
    j::LButton      ;攻擊(滑鼠左鍵)
    k::RButton     ;閃避(滑鼠右鍵)
    l::MButton     ;取消(滑鼠中鍵)
    
    u::e            ;小技能
    i::q            ;終結技

    ; mouse speed variables
    global FORCE := 1.8
    global RESISTANCE := 0.982

    global VELOCITY_X := 0
    global VELOCITY_Y := 0

    $e::return
    $q::return
    n::return
    m::return
    
    Accelerate(velocity, pos, neg) {
        If (pos == 0 && neg == 0) {
          Return 0
        }
        ; smooth deceleration :)
        Else If (pos + neg == 0) {
          Return velocity * 0.666
        }
        ; physicszzzzz
        Else {
          Return velocity * RESISTANCE + FORCE * (pos + neg)
        }
    }

    SetTimer MoveCursor, 16
    MoveCursor() {
        global
        if(!WinActive("ahk_group HoYoGame"))
            SetTimer MoveCursor, 0 
            ToolTip VELOCITY_X "," VELOCITY_Y, 0, 0
        LEFT := 0
        DOWN := 0
        UP := 0
        RIGHT := 0

        UP := UP -  GetKeyState("n", "P")
        LEFT := LEFT - GetKeyState("q", "P")
        DOWN := DOWN + GetKeyState("m", "P")
        RIGHT := RIGHT + GetKeyState("e", "P")
        
        VELOCITY_X := Accelerate(VELOCITY_X, LEFT, RIGHT)
        VELOCITY_Y := Accelerate(VELOCITY_Y, UP, DOWN)

        DllCall("mouse_event", "UInt", 0x0001, "UInt", VELOCITY_X, "UInt", 0)
        DllCall("mouse_event", "UInt", 0x0001, "UInt", 0, "UInt", VELOCITY_Y)
    }
#HotIf