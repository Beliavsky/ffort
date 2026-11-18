program p
implicit none
integer::a(4)=[1,2,3,4],b(4)=0
where(a<2)
a=9
elsewhere(a==3)
b=3
elsewhere
b=8
end where
print *,a,b
end program
