program p
implicit none
character(7)::s
if(s%len/=7.or.kind(s%len)/=kind(1)) error stop 1
end program
