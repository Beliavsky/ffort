program t
implicit none
character(3)::s
s='abc'
print '(a)',s(1_8:2_8)
end program
