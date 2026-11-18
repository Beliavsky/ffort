program test
implicit none
character(3)::s
integer::i
s='abc'
i=4
if(s(1:i)=='') error stop 1
end program
