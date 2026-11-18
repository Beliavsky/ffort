program p
implicit none
real,allocatable::a(:,:)
print '(a)','SAFE'
print '(2i3)',lbound(a,kind=8)
end program
