program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer(4)::s
allocate(b(2),c(2))
deallocate(a,b,c,stat=s)
print *,s>0,allocated(a),allocated(b),allocated(c)
end program
