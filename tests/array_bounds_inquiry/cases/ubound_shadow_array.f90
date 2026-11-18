program p
implicit none
integer::ubound(2)=[11,22]
if(ubound(2)/=22)error stop 1
end program
