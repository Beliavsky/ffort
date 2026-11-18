program p
implicit none
integer::a(-2:2)=[1,2,3,4,5]
where(a(2:-2:-1)>2) a(-2:2)=a(2:-2:-1)
print *,a
end program
