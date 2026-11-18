program main
implicit none
character(32769)::s
s=repeat('x',32769)
print '(2(a))',s,s
end program
