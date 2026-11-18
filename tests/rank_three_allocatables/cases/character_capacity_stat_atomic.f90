program p
character(65536),allocatable::a(:,:,:),b(:,:,:)
integer::s
allocate(a(-1:3,4:8,7:14),stat=s)
if(s/=0) error stop 1
a='x'
allocate(b(5,5,4),stat=s)
print *,s/=0,allocated(b),size(a),len(a),lbound(a,3),ubound(a,3)
deallocate(a)
allocate(b(5,5,4),stat=s)
print *,s,allocated(b),size(b),len(b)
end program
