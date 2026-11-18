program p
implicit none
character(:),allocatable::s(:)
s=[character(3)::'a','b']
if(s%len/=3) error stop 1
s=[character(5)::'xyz']
if(s%len/=5) error stop 2
end program
