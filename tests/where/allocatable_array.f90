program p
implicit none
integer,allocatable::a(:)
allocate(a(-1:2))
a=[1,2,3,4]
where(a>2) a=9
print *,lbound(a,1),a
end program
