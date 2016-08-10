MySignature =
(
Kind Regards,


Javy de Koning
Sr. Windows Engineer
IPsoft, Inc.
Javy.deKoning@ipsoft.com
http://www.ipsoft.com
Direct: {+}31(0)20-562-5260 / Mobile: {+}31(0)6-2047-3502
)

MyClose = 
(
Hence, we are now closing this ticket. Feel free to re-open this case if in case you require any further assistance on this matter. If you need immediate assistance, please call {+}1 (866) IPSOFT6.

%MySignature%
)

MyRecovery =
(
All Alerts have recovered. %MyClose%
)

::sig::
SendInput %MySignature%
return 

::cl::
SendInput %MyClose%
return

::rc::
SendInput %MyRecovery%
return

::mvg::
SendInput Met vriendelijke groet,
return

::jdk::
SendInput Javy de Koning
return