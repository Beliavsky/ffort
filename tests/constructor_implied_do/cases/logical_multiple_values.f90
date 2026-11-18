program main
implicit none
integer::i
logical::a(6)
a=[(i>1,(i==2),i=1,3)]
print *,a
end program
