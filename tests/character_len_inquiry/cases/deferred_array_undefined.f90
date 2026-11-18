program p
implicit none
character(:),allocatable::s(:,:)
allocate(character(3)::s(2,2))
if(s%len/=3) error stop 1
end program
