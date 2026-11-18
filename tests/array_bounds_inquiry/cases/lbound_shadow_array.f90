program p
implicit none
integer::lbound(2)=[11,22]
if(lbound(2)/=22)error stop 1
end program
