program p
implicit none
character(7),allocatable::s
integer,parameter::n=s%len
if(n/=7.or.allocated(s)) error stop 1
end program
