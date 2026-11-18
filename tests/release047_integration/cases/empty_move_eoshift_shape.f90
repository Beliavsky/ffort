program p
implicit none
integer,allocatable::a(:),b(:)
integer::c(0)
allocate(a(0))
call move_alloc(a,b)
c=eoshift(b,huge(0))
print '(l1,3i3)',allocated(a),size(b),size(c),kind(eoshift(b,1))
end program
