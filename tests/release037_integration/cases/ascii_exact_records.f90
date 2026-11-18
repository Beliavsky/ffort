program main
implicit none
character(3)::s
character(1)::a(4)
integer(8)::v(4)
s='Az0'
a(1)=s(1:1)
a(2)=s(2:2)
a(3)=achar(0)
a(4)=achar(127)
v=iachar(c=a,kind=8)
write(*,'("codes:",4(1x,i0))')v
write(*,'("text:[",a,"]",1x,i0)')achar(iachar(s(1:1))),iachar(s(3:3))
end program
