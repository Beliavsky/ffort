program main
implicit none
integer,allocatable::a(:)
integer(8)::s
deallocate(a,stat=s)
print *,s/=0,allocated(a)
allocate(a(2),stat=s)
a=7
print *,s,allocated(a)
allocate(a(4),stat=s)
print *,s/=0,size(a),sum(a)
deallocate(a,stat=s)
print *,s,allocated(a)
end program
