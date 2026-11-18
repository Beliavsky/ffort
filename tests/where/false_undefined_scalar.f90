program p
implicit none
integer::a(2)=1,b
where(a<0) a=b
print *,a
end program
