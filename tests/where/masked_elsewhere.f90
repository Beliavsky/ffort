program p
implicit none
integer::a(5)=[1,2,3,4,5],b(5)=0
where(a<3)
b=10
elsewhere(a<5)
b=20
elsewhere
b=30
end where
print *,b
end program
