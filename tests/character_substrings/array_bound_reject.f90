program test
implicit none
character(3)::s
integer::i(1)
s='abc'
i=1
print *,s(i:2)
end program
