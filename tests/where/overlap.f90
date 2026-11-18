program p
implicit none
integer::a(6)=[1,2,3,4,5,6]
where(a(2:6)>0) a(2:6)=a(1:5)
print *,a
end program
