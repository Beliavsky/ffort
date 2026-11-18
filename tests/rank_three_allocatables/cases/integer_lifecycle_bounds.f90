program p
integer,allocatable::a(:,:,:)
integer::s
print *,allocated(a)
allocate(a(-1:0,4:5,-3:-1),stat=s)
a=2
a(0,5,-1)=9
print *,s,allocated(a),size(a),size(a,3),lbound(a,1),lbound(a,2),lbound(a,3),ubound(a,3)
print *,sum(a(:,:,-3))+sum(a(:,:,-2))+sum(a(:,:,-1)),a(0,5,-1)
deallocate(a,stat=s)
print *,s,allocated(a)
end program
