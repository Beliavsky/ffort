program test
implicit none
character(4)::s
s='abcd'
s(2:3)=s(4:2)
print '(a)',s
end program
