program test
implicit none
character(3)::s(1)
s='abc'
print *,s(1)(1:2)
end program
