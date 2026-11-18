program p
implicit none
integer(8),allocatable::a(:)
real(8),allocatable::b(:,:)
logical,allocatable::c(:,:,:)
character(2),allocatable::d(:)
integer(8)::s
allocate(a(-2:1),b(2,3),c(1,2,3),d(2),stat=s)
a=2147483649_8
b=1.5_8
c=.true.
d="xy"
print *,s,sum(a),sum(b),size(c),all(d=="xy")
deallocate(a,b,c,d,stat=s)
print *,s,allocated(a),allocated(b),allocated(c),allocated(d)
end program
