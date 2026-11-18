program p
implicit none
logical,save :: a(-1:0,2:3)=.false.
a=.not.a
print *, all(a)
end program
