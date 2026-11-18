program p
implicit none
character(3),parameter::s(2)=['abc','def']
if(s%len/=3) error stop 1
end program
