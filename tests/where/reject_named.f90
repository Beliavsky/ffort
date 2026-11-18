program p
implicit none
integer::a(2)=0
x: where(a==0)
a=1
end where x
end program
