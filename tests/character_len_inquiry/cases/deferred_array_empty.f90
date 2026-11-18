program p
implicit none
character(:),allocatable::s(:)
allocate(character(9)::s(0))
if(s%len/=9.or..not.allocated(s)) error stop 1
end program
