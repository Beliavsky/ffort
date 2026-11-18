program p
implicit none
integer,allocatable::a(:)
allocate(a(3));a=0
where([.true.,.false.]) a=[1,2]
end program
