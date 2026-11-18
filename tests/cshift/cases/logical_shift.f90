program p
implicit none
integer::a(3)
a=cshift([1,2,3],.true.)
print *, "PASS"
end program
