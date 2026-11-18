program p
implicit none
character(7)::s(2,3)
if(s%len/=7.or.kind(s%len)/=4) error stop 1
end program
