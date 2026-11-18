program p
implicit none
integer::i
integer,allocatable::a(:)
allocate(a(-1:1))
forall(i=-1:1) a(i)=i*10
print *,a,lbound(a,1)
end program
