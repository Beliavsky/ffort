program p
implicit none
integer,parameter::a(3)=[1,2,3]
integer,parameter::b(3)=a(3:1:-1)
print *,b
end program p
