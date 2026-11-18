program p
implicit none
integer::a(2)=0
if(.true.) where(a==0)
a=1
end where
end program
