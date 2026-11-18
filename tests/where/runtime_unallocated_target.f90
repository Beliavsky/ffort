program p
implicit none
integer,allocatable::a(:)
where([.true.,.false.]) a=1
end program
