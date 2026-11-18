program main
implicit none
character(2)::x(2)
integer::idx(2)
x=['ab','cd']
idx=[1,3]
write(*,'(a)',advance='no')'SAFE'
print '(a)',x(idx)
end program
