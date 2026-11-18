program p
implicit none
integer::a(2,3),b(3,2)
a=1
b=2
print *,merge(a,b,.true.)
end program
