program p
implicit none
character(:),allocatable::s
s='abcdef'
if(s%len/=6) error stop 1
s='x'
if(s%len/=1) error stop 2
s=''
if(s%len/=0.or..not.allocated(s)) error stop 3
end program
