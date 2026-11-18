program p
implicit none
character(*),parameter::s='abcde'
if(s%len/=5) error stop 1
end program
