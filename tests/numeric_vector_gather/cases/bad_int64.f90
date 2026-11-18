program p
implicit none
integer::a(2),b(1)
a=1
b=a([huge(0_8)])
end program
