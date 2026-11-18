program p
implicit none
integer,parameter::a(3)=[1,2,3]
integer,parameter::b(2)=a(:)
print *,b
end program p
