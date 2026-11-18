program test
implicit none
character(3)::s
integer::i
s='abc'
if(s(i:2)=='') error stop 1
end program
