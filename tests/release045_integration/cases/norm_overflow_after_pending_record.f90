program p
implicit none
real(8)::v(2)
v=huge(0d0)
write(*,'(a)',advance='no')'SAFE'
print '(g0)',norm2(v)
end program
