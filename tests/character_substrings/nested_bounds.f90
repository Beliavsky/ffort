program test
implicit none
character(6)::s
s='abcdef'
print '(a)',s(len(s(2:3)):len(s(:4)))
end program
