program p
implicit none
character(7)::s
integer,parameter::n=s%len
if(n/=7.or.kind(n)/=4) error stop 1
end program
