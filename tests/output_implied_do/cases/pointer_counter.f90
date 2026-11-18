program main
implicit none
integer,pointer::i
integer,target::j
i=>j
print *, (i,i=1,3)
end program
