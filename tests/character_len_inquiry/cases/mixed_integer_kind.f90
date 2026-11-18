program p
implicit none
character(7)::s
integer(8)::n
n=s%len+1_8
if(n/=8_8.or.kind(s%len)/=4) error stop 1
end program
