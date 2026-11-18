program p
implicit none
character(7),allocatable::s(:,:)
if(s%len/=7.or.allocated(s)) error stop 1
end program
