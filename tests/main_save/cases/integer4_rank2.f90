program p
implicit none
integer,save :: a(-1:0,2:3)=2
a=a+3
print *, all(a==5)
end program
