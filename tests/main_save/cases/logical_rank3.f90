program p
implicit none
logical,save :: a(-1:0,2:3,-2:-1)=.false.
a=.not.a
print *, a
end program
