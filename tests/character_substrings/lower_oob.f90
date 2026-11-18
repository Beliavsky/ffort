program test
implicit none
character(3)::s
integer::i
s='abc'
i=0
s(i:2)='x'
end program
