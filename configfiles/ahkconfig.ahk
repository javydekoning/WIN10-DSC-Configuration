; ########################
; My multiline strings:  #
; ########################

MySignature =
(
Kind Regards,


Javy de Koning
jdekoning@javydekoning.com
http://www.javydekoning.com
Mobile: {+}31(0)6-2047-3502
)

MyClose = 
(
Hence, we are now closing this ticket. Feel free to re-open this case if in case you require any further assistance on this matter.

%MySignature%
)

MyRecovery =
(
All Alerts have recovered. %MyClose%
)

MyCurrentStatusRecovery =
(
Hi, the current status is displayed below.
)


; ########################
; Hotstrings:            #
; ########################

::cs::
	SendInput, %MyCurrentStatusRecovery% `n`n----------`n%clipboard%`n----------`n`n%MyClose%
return

::sig::
	SendInput, %MySignature%
return

::cl::
	SendInput, %MyClose%
return

::rc::
	SendInput, %MyRecovery%
return

::mvg::
	SendInput, Met vriendelijke groet,
return

::jdk::
	SendInput, Javy de Koning
return


; ########################
; HotKeys:               #
; ########################

;Send to Evernote
<^<!e::
	ClipSaved := ClipboardAll
	clipboard = javydekoning.55f32a5@m.evernote.com
	SendInput, ^f
	Sleep, 500
	SendInput, ^v
	SendInput, {enter}
	SendInput, ^{enter}
	Sleep, 500
	Clipboard := ClipSaved
Return

;Detach IPpm
<^<!m::
	SendInput, {tab}
	SendInput, {tab}
	SendInput, {enter}
Return
