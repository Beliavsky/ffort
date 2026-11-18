program p
implicit none
integer::a(3)=1,k=0
where(a>0) a(::k)=3
end program
