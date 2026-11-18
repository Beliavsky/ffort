program p
integer,allocatable::a(:,:,:)
integer::s
allocate(a(-2:-1,3:3,7:8)); a=5
allocate(a(1,1,1),stat=s)
print *,s/=0,allocated(a),size(a),lbound(a,3),ubound(a,3),sum(a(:,:,7))+sum(a(:,:,8))
deallocate(a,stat=s)
print *,s,allocated(a)
deallocate(a,stat=s)
print *,s/=0,allocated(a)
end program
