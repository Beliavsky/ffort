program p
implicit none
character(:),allocatable::s
integer,parameter::k=kind(s%len)
if(k/=4) error stop 1
end program
